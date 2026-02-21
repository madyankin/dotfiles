# Grand Central Dispatch (GCD) Deep Dive

Complete reference for GCD: DispatchQueue, DispatchGroup, DispatchWorkItem, DispatchSemaphore, DispatchSource, barriers, and QoS.

## DispatchQueue Internals

GCD maintains a pool of threads managed by the OS. When you submit work to a queue:

- **Serial queues**: maintain one logical lane — one block at a time, FIFO
- **Concurrent queues**: dispatch multiple blocks simultaneously to the thread pool
- The **main queue** is a special serial queue always bound to the main thread

GCD dynamically grows and shrinks the thread pool based on demand and available CPU cores.

**Thread explosion risk**: if many concurrent queue blocks block (waiting on locks, I/O, semaphores), GCD creates more threads to compensate. This can exhaust thread limits and cause instability. Prefer async patterns over blocking in GCD blocks.

## DispatchQueue

### Creating Queues

```swift
// Serial queue — one task at a time
let serialQueue = DispatchQueue(label: "com.myapp.serial")

// Concurrent queue — multiple tasks in parallel
let concurrentQueue = DispatchQueue(
    label: "com.myapp.concurrent",
    attributes: .concurrent
)

// Serial queue with specific QoS
let highPriorityQueue = DispatchQueue(
    label: "com.myapp.highpriority",
    qos: .userInitiated
)

// Concurrent queue that is also initially inactive (must call .activate())
let lazyQueue = DispatchQueue(
    label: "com.myapp.lazy",
    attributes: [.concurrent, .initiallyInactive]
)
lazyQueue.activate()
```

### Dispatching Work

```swift
// async — returns immediately, block executes later
queue.async {
    performWork()
}

// sync — blocks calling thread until block completes
// ⚠️ Never call sync on a queue from within that queue (deadlock)
// ⚠️ Never call sync on main queue from main thread (deadlock)
queue.sync {
    let result = readSharedData()
    process(result)
}

// sync with return value
let result = queue.sync { computeResult() }

// async after delay
queue.asyncAfter(deadline: .now() + 2.0) {
    performDelayedWork()
}
queue.asyncAfter(deadline: .now() + .milliseconds(500)) {
    retryRequest()
}
```

### Global (System) Queues

```swift
// Pre-existing concurrent queues — don't create custom queues for one-off work
DispatchQueue.global(qos: .userInteractive).async { /* UI animations */ }
DispatchQueue.global(qos: .userInitiated).async { /* user-triggered work */ }
DispatchQueue.global(qos: .default).async { /* general work */ }
DispatchQueue.global(qos: .utility).async { /* long tasks */ }
DispatchQueue.global(qos: .background).async { /* sync, indexing */ }
DispatchQueue.global(qos: .unspecified).async { /* legacy, avoid */ }
```

### Main Queue

```swift
// Always use for UI updates
DispatchQueue.main.async {
    self.tableView.reloadData()
    self.activityIndicator.stopAnimating()
}

// Conditionally dispatch to main (useful in library code)
func updateUI(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async { block() }
    }
}
```

## QoS (Quality of Service)

QoS propagates upward — if a higher-QoS task depends on a lower-QoS queue, GCD boosts the lower queue's priority (priority inversion prevention).

| QoS | UI Impact | Use Case | Examples |
|-----|-----------|----------|----------|
| `.userInteractive` | Directly visible | Animations, scrolling | CADisplayLink callbacks, gesture response |
| `.userInitiated` | User is waiting | Button tap results | Fetching data after tap, opening file |
| `.default` | Indeterminate | General purpose | Default for most app work |
| `.utility` | Progress indicator visible | Longer operations | Import, export, computation |
| `.background` | Not visible | Opportunistic | Cloud sync, indexing, prefetch |

```swift
// QoS can be specified at queue creation or per-dispatch
DispatchQueue.global().async(qos: .userInitiated) {
    let result = processData()
    DispatchQueue.main.async { show(result) }
}
```

## DispatchGroup

Group tracks multiple async operations and notifies when all complete.

### Basic Usage

```swift
let group = DispatchGroup()

// Async dispatch — automatically enters/leaves group
group.async(execute: { fetchProfile() })  // shorthand doesn't exist — use enter/leave

// Manual enter/leave for existing async APIs
group.enter()
api.fetchUser { user in
    self.user = user
    group.leave()
}

group.enter()
api.fetchPosts { posts in
    self.posts = posts
    group.leave()
}

// Notify when all work completes
group.notify(queue: .main) {
    self.tableView.reloadData()
}
```

### With DispatchQueue

```swift
let group = DispatchGroup()

// queue.async with group — automatically managed
concurrentQueue.async(group: group) { task1() }
concurrentQueue.async(group: group) { task2() }
concurrentQueue.async(group: group) { task3() }

group.notify(queue: .main) { allDone() }
```

### Blocking Wait

```swift
// Blocks current thread — never use on main thread
let timeout = DispatchTime.now() + .seconds(10)
let result = group.wait(timeout: timeout)

switch result {
case .success: handleResults()
case .timedOut: handleTimeout()
}
```

### Nested Groups

```swift
let outerGroup = DispatchGroup()

for batch in batches {
    outerGroup.enter()
    processBatch(batch) {  // async
        outerGroup.leave()
    }
}

outerGroup.notify(queue: .main) {
    showCompletion()
}
```

## Barrier (Reader-Writer Pattern)

Barriers provide exclusive write access on concurrent queues while allowing concurrent reads.

```swift
class ThreadSafeCache<Key: Hashable, Value> {
    private var cache: [Key: Value] = [:]
    private let queue = DispatchQueue(
        label: "com.myapp.cache",
        attributes: .concurrent
    )

    func value(for key: Key) -> Value? {
        // Concurrent reads — multiple readers simultaneously
        queue.sync {
            cache[key]
        }
    }

    func setValue(_ value: Value, for key: String) {
        // Exclusive write — all reads finish before this runs,
        // and no reads start until this completes
        queue.async(flags: .barrier) {
            self.cache[key as! Key] = value
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}
```

**Rules:**
- Barriers only work on **custom concurrent queues** — not global queues
- A barrier on a global queue degrades to a regular async (not exclusive)
- Writes are async (non-blocking for caller) but exclusive to each other and to reads

## DispatchWorkItem

DispatchWorkItem wraps a block with cancellation support and the ability to notify on completion.

```swift
// Basic work item
var workItem: DispatchWorkItem?

workItem = DispatchWorkItem {
    guard !(workItem?.isCancelled ?? false) else { return }
    performExpensiveWork()
}

DispatchQueue.global().async(execute: workItem!)

// Cancel before it runs (or during, if it checks isCancelled)
workItem?.cancel()

// Notify on completion
workItem?.notify(queue: .main) {
    updateUI()
}
```

### Debouncing with DispatchWorkItem

```swift
class SearchDebouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.3) {
        self.delay = delay
    }

    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()

        let newItem = DispatchWorkItem(block: action)
        workItem = newItem

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newItem)
    }
}

// Usage
let debouncer = SearchDebouncer()
textField.addAction(UIAction { [weak self] _ in
    debouncer.debounce { self?.search(query: textField.text ?? "") }
}, for: .editingChanged)
```

## DispatchSemaphore

Semaphores control access to a resource by a limited number of concurrent tasks.

```swift
// Binary semaphore (mutex-like)
let semaphore = DispatchSemaphore(value: 1)
semaphore.wait()    // decrement; blocks if value would go below 0
defer { semaphore.signal() }  // increment
accessSharedResource()

// Counting semaphore — limit to N concurrent operations
let maxConcurrent = DispatchSemaphore(value: 3)

for url in urls {
    maxConcurrent.wait()  // blocks when 3 are already running
    DispatchQueue.global().async {
        defer { maxConcurrent.signal() }
        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
    }
}
```

**Critical warnings:**
- `semaphore.wait()` **blocks the calling thread** — never call on main thread
- Never call `semaphore.wait()` inside a Swift async function (blocks cooperative thread)
- In Swift Concurrency code, use `AsyncSemaphore` from swift-async-algorithms or an actor instead

### Async-Safe Alternative

```swift
// Actor-based semaphore for Swift Concurrency
actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int) { self.count = value }

    func wait() async {
        if count > 0 { count -= 1; return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            count += 1
        }
    }
}
```

## DispatchSource

DispatchSource monitors system events and dispatches handlers on a queue.

### Timer

```swift
class Timer {
    private var source: DispatchSourceTimer?

    func start(interval: TimeInterval, handler: @escaping () -> Void) {
        let source = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        source.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(50))
        source.setEventHandler(handler: handler)
        source.resume()  // sources start suspended — must call resume
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }
}
```

**Important:** Call `resume()` before using a source. Cancelling a suspended source crashes — either resume then cancel, or check before cancelling.

### File System Events

```swift
func watchDirectory(at url: URL, handler: @escaping () -> Void) -> DispatchSourceFileSystemObject {
    let fileDescriptor = open(url.path, O_EVTONLY)
    let source = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: fileDescriptor,
        eventMask: [.write, .delete, .rename],
        queue: .global(qos: .utility)
    )

    source.setEventHandler {
        let flags = source.data  // DispatchSource.FileSystemEvent
        if flags.contains(.delete) { handler() }
    }

    source.setCancelHandler {
        close(fileDescriptor)
    }

    source.resume()
    return source  // caller must hold reference; source cancelled when released
}
```

### Signal Handling

```swift
// Safely handle SIGTERM in GCD
signal(SIGTERM, SIG_IGN)  // ignore at POSIX level first
let signalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
signalSource.setEventHandler {
    print("Received SIGTERM — shutting down")
    exit(0)
}
signalSource.resume()
```

## DispatchIO

High-level channel-based I/O for efficient file and pipe operations:

```swift
// Channel for reading large files without blocking
let channel = DispatchIO(
    type: .stream,
    path: filePath,
    oflag: O_RDONLY,
    mode: 0,
    queue: .global(qos: .utility)
) { error in
    if error != 0 { print("Channel error: \(error)") }
}

channel.read(offset: 0, length: .max, queue: .global()) { done, data, error in
    data?.forEach { byte in process(byte) }
    if done { channel.close() }
}
```

## concurrentPerform

`DispatchQueue.concurrentPerform` is GCD's equivalent of a parallel `for` loop:

```swift
// Process an array in parallel — blocks until all complete
DispatchQueue.concurrentPerform(iterations: images.count) { index in
    processedImages[index] = resize(images[index])
    // ⚠️ processedImages must be thread-safe if shared
}
// All iterations complete here — safe to read processedImages
```

**Note:** Uses a pre-allocated array (not appending) to avoid race conditions. For dynamic accumulation, use a serial queue or DispatchGroup.

## Common Patterns & Pitfalls

### Avoiding Retain Cycles

```swift
// ❌ Strong capture creates retain cycle if self holds queue
queue.async {
    self.doWork()
}

// ✅ Weak capture
queue.async { [weak self] in
    self?.doWork()
}
```

### Checking Correct Queue

```swift
// Verify you're on the expected queue (for debugging/assertions)
let key = DispatchSpecificKey<Bool>()
let myQueue = DispatchQueue(label: "com.myapp.queue")
myQueue.setSpecific(key: key, value: true)

func assertOnMyQueue() {
    assert(DispatchQueue.getSpecific(key: key) == true, "Must be called on myQueue")
}
```

### Async vs Sync Decision

| Situation | Use |
|-----------|-----|
| Caller doesn't need result immediately | `async` |
| Caller needs result before continuing | `sync` (if different queue) |
| Accessing shared state from serial queue | `sync` |
| Updating UI from background | `.main.async` |
| Fire-and-forget background work | `.global().async` |

### Deadlock Checklist

1. Never call `sync` on queue A while already on queue A (self-deadlock)
2. Never call `sync` on the main queue from the main thread
3. If queue A calls `sync` on queue B, ensure B never calls `sync` on A (mutual deadlock)
4. `semaphore.wait()` and signal in the same serial queue → deadlock
