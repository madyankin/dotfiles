---
name: ios-concurrency
description: iOS/Swift concurrency expert - advises on Swift Concurrency (async/await, actors, TaskGroup), Grand Central Dispatch, Combine, OperationQueue, and Thread. Use when the user asks about iOS/macOS threading, parallelism, data races, deadlocks, MainActor, actor isolation, Sendable conformance, GCD queues, Dispatch barriers, Combine schedulers, or migrating from GCD to Swift Concurrency.
---

# iOS Concurrency Expert

Expert guidance on iOS and macOS concurrency across all layers: Swift Concurrency (modern), GCD, Combine, OperationQueue, and legacy Threading primitives. Covers thread safety, data races, actor isolation, and migration patterns.

## Concurrency Model at a Glance

| Primitive | Parallelism | Overhead | Scheduler | Best For |
|-----------|-------------|----------|-----------|----------|
| **Swift Task** (async/await) | ✅ True | Very low | Swift runtime cooperative | Modern async code, structured concurrency |
| **Swift Actor** | ✅ (serial per-actor) | Very low | Swift runtime | Shared mutable state, replacing locks |
| **DispatchQueue (serial)** | ❌ | Low | GCD (preemptive) | Serializing access, background work |
| **DispatchQueue (concurrent)** | ✅ True | Low | GCD (preemptive) | Parallel I/O, read-heavy workloads |
| **OperationQueue** | ✅ True | Medium | GCD under the hood | Dependency graphs, cancellable work |
| **Combine** | Depends on scheduler | Low | Configurable | Reactive pipelines, event streams |
| **Thread** | ✅ True | High | OS | Rarely—prefer higher abstractions |

## Swift Concurrency (async/await)

Swift Concurrency is the **preferred model** for all new iOS/macOS code (iOS 15+, Swift 5.5+).

### async/await Basics

```swift
// Mark a function async to allow suspension
func fetchUser(id: String) async throws -> User {
    let data = try await URLSession.shared.data(from: url).0
    return try JSONDecoder().decode(User.self, from: data)
}

// Call from async context
Task {
    do {
        let user = try await fetchUser(id: "42")
        updateUI(with: user)  // still on the calling actor's executor
    } catch {
        handleError(error)
    }
}
```

**Key rules:**
- `await` is a suspension point — the thread is freed, not blocked
- A suspended task resumes on the same actor it suspended from (unless you hop explicitly)
- `async` functions can only be called from async contexts or inside `Task { }`

### Structured Concurrency

Structured concurrency ties task lifetimes to scopes. Child tasks are cancelled when their scope exits.

```swift
// async let — launch multiple tasks, await results together
func loadDashboard() async throws -> Dashboard {
    async let profile = fetchProfile()
    async let feed = fetchFeed()
    async let notifications = fetchNotifications()
    // All three run concurrently; all must succeed
    return Dashboard(profile: try await profile,
                     feed: try await feed,
                     notifications: try await notifications)
}

// TaskGroup — dynamic number of concurrent tasks
func resizeImages(_ images: [UIImage]) async -> [UIImage] {
    await withTaskGroup(of: UIImage.self) { group in
        for image in images {
            group.addTask { await resizeSingle(image) }
        }
        var results: [UIImage] = []
        for await resized in group {
            results.append(resized)
        }
        return results
    }
}
```

### Task Cancellation

```swift
// Check cancellation explicitly
func processItems(_ items: [Item]) async throws {
    for item in items {
        try Task.checkCancellation()  // throws CancellationError if cancelled
        await process(item)
    }
}

// Cooperative cancellation — isCancelled is non-throwing
func longWork() async -> Result {
    while !Task.isCancelled {
        doSomeWork()
    }
    return .cancelled
}

// Cancel from outside
let task = Task {
    try await processItems(items)
}
task.cancel()  // propagates to all child tasks
```

### Task Priority

```swift
Task(priority: .userInitiated) { ... }  // high
Task(priority: .utility) { ... }        // low background
Task(priority: .background) { ... }     // lowest

// Detached task — not bound to current actor or priority
Task.detached(priority: .background) {
    await performBackgroundSync()
}
```

**Warning:** `Task.detached` breaks structured concurrency — the parent cannot cancel it. Prefer `Task { }` unless you explicitly need detachment.

See [Swift Concurrency deep dive](docs/swift-concurrency.md) for continuations, AsyncSequence, and clock/sleep APIs.

## Actors & MainActor

Actors are Swift's primary mechanism for protecting shared mutable state without explicit locks.

### Defining Actors

```swift
actor UserCache {
    private var cache: [String: User] = [:]

    func user(for id: String) -> User? {
        cache[id]
    }

    func insert(_ user: User, for id: String) {
        cache[id] = user
    }

    // nonisolated — can be called without await, no mutable state access
    nonisolated var description: String { "UserCache" }
}

// Callers must await every access
let cache = UserCache()
await cache.insert(user, for: user.id)
let cached = await cache.user(for: "42")
```

### Actor Reentrancy

Actors are reentrant: while a task is suspended inside an actor method, another task can run on the same actor. This can cause state to change across an `await`:

```swift
actor BankAccount {
    var balance: Double = 1000

    func withdraw(_ amount: Double) async {
        guard balance >= amount else { return }
        // ⚠️ Another withdrawal could run here, between the guard and the deduction
        await logTransaction(amount)  // suspension point
        balance -= amount             // balance may now be negative!
    }

    // Fix: complete state mutation before suspension
    func withdrawSafe(_ amount: Double) async {
        guard balance >= amount else { return }
        balance -= amount             // mutate first
        await logTransaction(amount) // then suspend
    }
}
```

### @MainActor

`@MainActor` guarantees code runs on the main thread. Use it for all UI work:

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []

    func loadItems() async {
        let fetched = try? await api.fetchItems()  // runs off main actor
        items = fetched ?? []                       // back on MainActor
    }
}

// Hop to MainActor from any async context
await MainActor.run {
    label.text = "Done"
}
```

See [Actors deep dive](docs/actors.md) for Sendable, global actors, actor isolation boundaries, and interop with ObjC.

## Grand Central Dispatch (GCD)

GCD remains widely used in production codebases and in UIKit/AppKit internal APIs.

### DispatchQueue Basics

```swift
// Serial queue — one task at a time, FIFO
let serialQueue = DispatchQueue(label: "com.app.serial")
serialQueue.async { doWork() }
serialQueue.sync { criticalSection() }  // blocks caller — never call on main queue

// Concurrent queue — multiple tasks in parallel
let concurrentQueue = DispatchQueue(label: "com.app.concurrent",
                                    attributes: .concurrent)
concurrentQueue.async { task1() }
concurrentQueue.async { task2() }

// Global queues (system-provided concurrent queues)
DispatchQueue.global(qos: .userInitiated).async { expensiveWork() }
DispatchQueue.global(qos: .background).async { syncToServer() }

// Main queue — serial, always on main thread
DispatchQueue.main.async { updateUI() }
```

### QoS Classes

| QoS | Use Case | Relative Priority |
|-----|----------|-------------------|
| `.userInteractive` | Animations, UI response | Highest |
| `.userInitiated` | User-triggered, awaiting result | High |
| `.default` | General work | Medium |
| `.utility` | Long tasks, progress visible | Low |
| `.background` | Sync, backups | Lowest |

### DispatchGroup

```swift
let group = DispatchGroup()

group.enter()
fetchProfile { profile in
    self.profile = profile
    group.leave()
}

group.enter()
fetchFeed { feed in
    self.feed = feed
    group.leave()
}

group.notify(queue: .main) {
    self.updateUI()
}

// Or block (avoid on main thread):
group.wait(timeout: .now() + 5)
```

### Barriers (Reader-Writer Pattern)

```swift
let queue = DispatchQueue(label: "com.app.rw", attributes: .concurrent)
var data: [String: Any] = [:]

// Reads run concurrently
func read(key: String) -> Any? {
    queue.sync { data[key] }
}

// Writes are exclusive — barrier blocks until all prior reads finish
func write(value: Any, for key: String) {
    queue.async(flags: .barrier) { self.data[key] = value }
}
```

### DispatchSemaphore

```swift
// Limit concurrent network requests to 3
let semaphore = DispatchSemaphore(value: 3)

for url in urls {
    semaphore.wait()
    URLSession.shared.dataTask(with: url) { _, _, _ in
        semaphore.signal()
    }.resume()
}
```

**Warning:** Never call `semaphore.wait()` on the main thread — it blocks the run loop.

See [GCD deep dive](docs/gcd.md) for DispatchSource, timers, I/O sources, and DispatchWorkItem.

## Combine

Combine is Apple's reactive framework for processing asynchronous event streams (iOS 13+).

### Core Concepts

```swift
import Combine

// Publisher — emits values over time
// Subscriber — receives values
// Operator — transforms values between publisher and subscriber

let cancellable = URLSession.shared
    .dataTaskPublisher(for: url)
    .map(\.data)
    .decode(type: User.self, decoder: JSONDecoder())
    .receive(on: DispatchQueue.main)       // switch to main for UI
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion { handle(error) }
        },
        receiveValue: { user in self.user = user }
    )
```

### Subjects (imperative bridge into Combine)

```swift
// PassthroughSubject — no initial value, doesn't replay
let events = PassthroughSubject<Event, Never>()
events.send(.userTapped)

// CurrentValueSubject — holds current value, replays to new subscribers
let isLoading = CurrentValueSubject<Bool, Never>(false)
isLoading.value = true
```

### Schedulers

```swift
// subscribeOn — where upstream work runs
// receive(on:) — where downstream (sink/assign) runs

publisher
    .subscribe(on: DispatchQueue.global(qos: .background))  // upstream on bg thread
    .receive(on: RunLoop.main)                               // downstream on main thread
```

### Memory Management

```swift
// Store cancellables or they'll be deallocated immediately
var cancellables = Set<AnyCancellable>()

publisher
    .sink { value in print(value) }
    .store(in: &cancellables)  // tied to object lifetime
```

See [Combine deep dive](docs/combine.md) for backpressure, custom publishers, error handling, and async/Combine interop.

## Legacy: OperationQueue & Thread

### OperationQueue

```swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 4

// Block operation
queue.addOperation {
    performWork()
}

// Dependency graph
let op1 = BlockOperation { fetchData() }
let op2 = BlockOperation { processData() }
op2.addDependency(op1)  // op2 waits for op1

queue.addOperations([op1, op2], waitUntilFinished: false)

// Cancellation
queue.cancelAllOperations()
```

### Thread

Avoid raw `Thread` in new code. Use only when interfacing with C APIs requiring thread affinity.

```swift
// Rarely needed — prefer Task or DispatchQueue
let thread = Thread {
    RunLoop.current.run()  // keep thread alive if using RunLoop
}
thread.qualityOfService = .utility
thread.start()
```

See [Legacy concurrency](docs/legacy.md) for NSLock, NSRecursiveLock, RunLoop details, and NSOperation subclassing.

## Common Patterns

### Parallel Network Requests (Modern)

```swift
func loadDashboard() async throws -> Dashboard {
    async let profile = try await api.fetchProfile()
    async let feed = try await api.fetchFeed()
    return Dashboard(profile: try await profile, feed: try await feed)
}
```

### Safe UI Updates from Background

```swift
// Modern
Task { @MainActor in
    self.tableView.reloadData()
}

// GCD fallback (UIKit/AppKit callbacks)
DispatchQueue.main.async {
    self.tableView.reloadData()
}
```

### Wrapping Completion Handlers (Bridging to async)

```swift
// withCheckedThrowingContinuation bridges callback APIs to async/await
func fetchData(from url: URL) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error { continuation.resume(throwing: error) }
            else if let data { continuation.resume(returning: data) }
            else { continuation.resume(throwing: URLError(.badServerResponse)) }
        }.resume()
    }
}
```

**Rule:** Never call `resume` more than once — it crashes. Ensure all code paths resume exactly once.

### Throttling Concurrent Work

```swift
// TaskGroup with limited concurrency
func processInBatches(_ items: [Item], concurrency: Int = 4) async {
    await withTaskGroup(of: Void.self) { group in
        var active = 0
        for item in items {
            if active >= concurrency {
                await group.next()  // wait for one to finish
                active -= 1
            }
            group.addTask { await self.process(item) }
            active += 1
        }
    }
}
```

### Actor-Isolated Cache

```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache[url] { return cached }

        // Coalesce duplicate in-flight requests
        if let existing = inFlight[url] { return try await existing.value }

        let task = Task { try await downloadImage(from: url) }
        inFlight[url] = task
        defer { inFlight.removeValue(forKey: url) }

        let image = try await task.value
        cache[url] = image
        return image
    }
}
```

## Diagnosing Issues

### Thread Sanitizer (TSan)

Enable in Xcode: **Product → Scheme → Run → Diagnostics → Thread Sanitizer**

TSan detects data races at runtime with ~5–10× slowdown. Run UI flows and background operations together to trigger races.

### Instruments

- **Time Profiler**: see which threads are consuming CPU
- **System Trace**: visualize thread scheduling, preemptions, and queue hops
- **Swift Concurrency** template (Xcode 14+): visualize task trees, actor contention, and cooperative thread pool usage

### Detecting Deadlocks

```swift
// Common causes:
// 1. sync() on the same serial queue from within that queue
serialQueue.sync {
    serialQueue.sync { }  // ← DEADLOCK
}

// 2. semaphore.wait() on main thread while signal() needs main thread
DispatchQueue.main.async {
    semaphore.wait()          // blocks main thread
    // signal() called from a completion that dispatch.async's to main → deadlock
}

// 3. Two queues calling sync on each other
```

### Main Thread Checker

Enabled by default in debug builds. Catches UIKit/AppKit calls off main thread at runtime.

```swift
// Will trigger Main Thread Checker warning:
DispatchQueue.global().async {
    self.label.text = "hello"  // ⚠️ UIKit call off main thread
}
```

### Swift Concurrency Debugging

```swift
// Check if running on expected executor
// In Swift 5.9+ you can assert isolation:
func updateLabel() {
    MainActor.assertIsolated()  // crashes if not on MainActor
}

// SWIFT_UNEXPECTED_EXECUTOR_LOG=1 environment variable prints warnings
// when code runs on unexpected executors
```

## Decision Guide

**New code, iOS 15+**: Use **Swift Concurrency** (async/await + actors) exclusively. It's the best model for correctness, performance, and readability.

**Wrapping legacy callback APIs**: Use `withCheckedThrowingContinuation` / `withCheckedContinuation` to bridge into async/await.

**Protecting shared mutable state**: Use **actor** (modern) or a **serial DispatchQueue** (GCD). Avoid raw locks unless profiling shows actor overhead matters.

**Reader-heavy shared state**: Use a **concurrent queue with barrier writes** (GCD reader-writer pattern).

**Reactive event streams / UI bindings**: Use **Combine** (or SwiftUI's `@Published`/`@StateObject` which wrap Combine internally).

**Dependency graphs with cancellation**: Use **OperationQueue** with `addDependency`, or model as structured Swift tasks.

**CPU-bound parallelism**: Use **TaskGroup** (Swift Concurrency) or `DispatchQueue.concurrentPerform` (GCD).

**Never do**: Call `DispatchQueue.sync` on the main queue from any code that may be called from main, use `Thread.sleep` on main thread, or `semaphore.wait()` on main thread.

## Reference Docs

- [Swift Concurrency](docs/swift-concurrency.md) — async/await, structured concurrency, AsyncSequence, continuations, clocks
- [Actors & Sendable](docs/actors.md) — actor isolation, MainActor, global actors, Sendable, ObjC interop
- [Grand Central Dispatch](docs/gcd.md) — queues, groups, barriers, semaphores, DispatchSource, timers
- [Combine](docs/combine.md) — publishers, operators, schedulers, backpressure, async interop
- [Legacy (Thread, OperationQueue, RunLoop)](docs/legacy.md) — NSLock, NSRecursiveLock, RunLoop, NSOperation subclassing
