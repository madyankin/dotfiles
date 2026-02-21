# Swift Concurrency Deep Dive

Complete reference for Swift Concurrency: async/await mechanics, structured concurrency, AsyncSequence, continuations, clocks, and the cooperative thread pool.

## How async/await Works Internally

Swift Concurrency uses a **cooperative thread pool** — a fixed set of threads (typically matching CPU core count) that tasks share by suspending and resuming cooperatively.

- A task **suspends** at `await`: it releases the thread, saves its state (continuation)
- The thread picks up another ready task from the queue
- When the awaited work completes, the task's continuation is **enqueued for resumption**
- Resumption happens on the correct executor (actor or cooperative pool)

**Key contrast with GCD**: GCD creates new threads when queues block, leading to thread explosion. Swift Concurrency's cooperative pool stays bounded — threads never block, they suspend.

```
Thread Pool (N threads, N ≈ CPU cores)
├── Thread 1: running Task A → suspends at await URLSession → picks up Task B
├── Thread 2: running Task C → suspends at await db.fetch → picks up Task D
└── Thread N: ...

When URLSession completes: Task A's continuation is re-enqueued, resumes on next free thread
```

## async/await in Depth

### Suspension Points

Every `await` is a **potential** suspension point — the runtime may or may not actually suspend depending on whether the awaited expression completes synchronously.

```swift
// This might not suspend at all if cache hit is synchronous
let value = await cache.get(key)  // actor hop may suspend; reading is instant

// This almost certainly suspends — network I/O
let data = try await URLSession.shared.data(from: url)
```

### async Properties and Subscripts

```swift
actor DataStore {
    var latestSnapshot: Snapshot {
        get async {
            await computeExpensiveSnapshot()
        }
    }
}

let snapshot = await store.latestSnapshot
```

### async Sequences (for await)

```swift
// Read lines from a URL asynchronously
let (bytes, _) = try await URLSession.shared.bytes(from: url)
for try await line in bytes.lines {
    process(line)
}

// AsyncStream — bridge push-based sources to AsyncSequence
func locationUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
        let delegate = LocationDelegate { location in
            continuation.yield(location)
        }
        continuation.onTermination = { _ in delegate.stop() }
        delegate.start()
    }
}

for await location in locationUpdates() {
    updateMap(location)
}
```

### AsyncThrowingStream

```swift
func watchFile(at url: URL) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        let watcher = FileWatcher(url: url)
        watcher.onLine = { line in continuation.yield(line) }
        watcher.onError = { error in continuation.finish(throwing: error) }
        watcher.onEnd = { continuation.finish() }
        continuation.onTermination = { _ in watcher.stop() }
        watcher.start()
    }
}
```

## Structured Concurrency

Structured concurrency guarantees:
1. Child tasks cannot outlive their parent scope
2. Cancellation propagates from parent to all children
3. Errors from children are collected and rethrown

### async let

Best for a **fixed, known number** of concurrent operations whose results are all needed:

```swift
func loadUserProfile(id: String) async throws -> FullProfile {
    async let user = fetchUser(id: id)
    async let posts = fetchPosts(userId: id)
    async let followers = fetchFollowers(userId: id)

    // All three launch immediately in parallel.
    // If any throws, the others are cancelled.
    return FullProfile(
        user: try await user,
        posts: try await posts,
        followers: try await followers
    )
}
```

**Important:** Unawaited `async let` bindings are automatically cancelled when leaving scope.

### withTaskGroup

Best for a **dynamic number** of tasks or when collecting results as they arrive:

```swift
// Collecting all results
func downloadAll(urls: [URL]) async throws -> [Data] {
    try await withThrowingTaskGroup(of: (Int, Data).self) { group in
        for (index, url) in urls.enumerated() {
            group.addTask {
                let (data, _) = try await URLSession.shared.data(from: url)
                return (index, data)
            }
        }
        // Results arrive in completion order, not submission order
        var results = [Int: Data]()
        for try await (index, data) in group {
            results[index] = data
        }
        return urls.indices.compactMap { results[$0] }
    }
}

// Processing results as they arrive (streaming)
func processAsAvailable(items: [Item]) async {
    await withTaskGroup(of: Result.self) { group in
        for item in items {
            group.addTask { await process(item) }
        }
        for await result in group {
            await updateUI(with: result)  // each result immediately applied
        }
    }
}
```

### Task Group Cancellation Behavior

```swift
// withThrowingTaskGroup: first error cancels all siblings
try await withThrowingTaskGroup(of: Data.self) { group in
    group.addTask { try await riskyFetch1() }
    group.addTask { try await riskyFetch2() }
    // If riskyFetch1 throws: riskyFetch2 receives cancellation, group rethrows error
}

// Handling partial failures manually
await withTaskGroup(of: Result<Data, Error>.self) { group in
    for url in urls {
        group.addTask {
            do { return .success(try await fetch(url)) }
            catch { return .failure(error) }
        }
    }
    for await result in group {
        switch result {
        case .success(let data): handle(data)
        case .failure(let error): log(error)  // don't cancel others
        }
    }
}
```

## Task API

### Creating Tasks

```swift
// Inherits actor context, priority, and task-local values from caller
let task = Task {
    try await someWork()
}

// Fully independent — no inherited context
let detached = Task.detached(priority: .background) {
    await backgroundSync()
}

// Access result (suspends until done, rethrows errors)
let result = try await task.value
```

### Task Properties

```swift
Task.currentPriority           // current task's effective priority
Task.isCancelled               // Bool — cooperative cancel check
try Task.checkCancellation()   // throws CancellationError if cancelled
await Task.yield()             // voluntarily yields to other tasks (fairness)
```

### Task Locals

Task-local values propagate to child tasks automatically:

```swift
@TaskLocal static var requestID: String = "unknown"

// Set for the scope of a closure
await Task.$requestID.withValue("req-123") {
    await handleRequest()  // requestID == "req-123" here
    // Any child tasks spawned here inherit requestID == "req-123"
}
```

## Continuations

Continuations bridge callback-based APIs to async/await. They must be resumed **exactly once**.

### withCheckedContinuation

```swift
// Non-throwing version
func currentLocation() async -> CLLocation {
    await withCheckedContinuation { continuation in
        locationManager.requestLocation { location in
            continuation.resume(returning: location)
        }
    }
}

// Throwing version
func fetchData(from url: URL) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        session.dataTask(with: url) { data, response, error in
            if let error {
                continuation.resume(throwing: error)
            } else if let data {
                continuation.resume(returning: data)
            } else {
                continuation.resume(throwing: URLError(.unknown))
            }
        }.resume()
    }
}
```

### withUnsafeContinuation

Like `withCheckedContinuation` but without runtime checking. Marginally faster; prefer the checked variant unless you've profiled a need:

```swift
// Only use if profiling shows checked continuation overhead matters
func fastBridge() async -> Result {
    await withUnsafeContinuation { continuation in
        callback { result in continuation.resume(returning: result) }
    }
}
```

### Common Continuation Pitfalls

```swift
// ❌ CRASH: resuming twice
func bad() async -> Int {
    await withCheckedContinuation { continuation in
        doWork { result in
            continuation.resume(returning: result)
        }
        continuation.resume(returning: 0)  // also runs — crash!
    }
}

// ❌ LEAK: never resumed (task hangs forever)
func leaky() async -> Int {
    await withCheckedContinuation { continuation in
        doWork { result in
            if result > 0 {
                continuation.resume(returning: result)
                // If result <= 0: continuation never resumed — memory leak + hung task
            }
        }
    }
}

// ✅ Always resume exactly once on all code paths
func correct() async -> Int {
    await withCheckedContinuation { continuation in
        doWork { result in
            continuation.resume(returning: max(0, result))
        }
    }
}
```

## Clocks and Sleep

Swift 5.7+ introduced the `Clock` protocol for testable, type-safe time handling.

```swift
// Sleep (preferred over Task.sleep(nanoseconds:))
try await Task.sleep(for: .seconds(2))
try await Task.sleep(for: .milliseconds(500))
try await Task.sleep(until: .now + .seconds(30), clock: .continuous)

// ContinuousClock — wall clock time, pauses when device sleeps
let clock = ContinuousClock()
let elapsed = await clock.measure {
    try? await Task.sleep(for: .seconds(1))
}

// SuspendingClock — pauses when device sleeps (for scheduling real-world timing)
// Use ContinuousClock for most cases
```

### Testable Time with Clock Protocol

```swift
// Protocol-driven time allows injection in tests
func poll<C: Clock>(every interval: C.Duration, clock: C = .continuous,
                    work: @escaping () async -> Void) async {
    while !Task.isCancelled {
        await work()
        try? await Task.sleep(for: interval, clock: clock)
    }
}

// In tests: inject a mock clock that advances on demand
```

## Cooperative Thread Pool & Back-pressure

The cooperative thread pool has **CPU-count threads**. Avoid blocking these threads:

```swift
// ❌ Blocks a cooperative thread — starves other tasks
func bad() async {
    Thread.sleep(forTimeInterval: 5)  // blocks the OS thread
}

// ✅ Suspends cooperatively — thread freed for other tasks
func good() async {
    try? await Task.sleep(for: .seconds(5))
}

// ❌ Semaphore.wait() on cooperative thread — potential deadlock
func alsoBAD() async {
    semaphore.wait()  // blocks thread; signal() may need that thread → deadlock
}
```

For **CPU-intensive work** that would monopolize a cooperative thread, use `Task.yield()` periodically or dispatch to a custom thread pool via `withCheckedContinuation`.

## Swift Concurrency + Objective-C

```swift
// ObjC completion handlers auto-generate async variants in Swift 5.5+
// ObjC:
// - (void)fetchUserWithID:(NSString *)id completion:(void(^)(User *, NSError *))completion;

// Swift sees:
func fetchUser(withID id: String) async throws -> User

// @objc async methods — marked with NS_SWIFT_ASYNC_NAME
// @objc methods can be called from async context with explicit hop
```

## Performance Considerations

| Scenario | Recommendation |
|----------|----------------|
| Many short-lived tasks | Task overhead is ~100ns — fine for thousands |
| CPU-bound parallel work | TaskGroup over GCD — avoids thread explosion |
| High-frequency events | AsyncStream with a buffer to avoid task-per-event |
| Actor hot path | `nonisolated` for read-only computed properties |
| Bridging synchronous code | `withCheckedContinuation` on a background actor |
