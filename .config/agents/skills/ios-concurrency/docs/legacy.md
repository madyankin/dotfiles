# Legacy Concurrency: Thread, RunLoop, OperationQueue, NSLock

Reference for pre-Swift-Concurrency and pre-GCD primitives. These APIs are stable and still appear frequently in existing codebases, system frameworks, and C/ObjC interop layers.

**General guidance:** Prefer Swift Concurrency (actors, async/await) for new code. Use these APIs when:
- Maintaining existing code that uses them
- Interfacing with system frameworks that expose callbacks on specific threads
- Working with C/ObjC libraries requiring thread affinity (e.g., SQLite in serialized mode, OpenGL/Metal from specific threads)
- Implementing low-level synchronization where lock overhead matters

## Thread

`Thread` (bridged from `NSThread`) creates OS threads directly. Each `Thread` maps 1:1 to an OS thread with its own stack.

### Creating Threads

```swift
// Block-based (simplest)
let thread = Thread {
    performWork()
}
thread.name = "com.myapp.worker"
thread.qualityOfService = .utility
thread.stackSize = 512 * 1024  // default is 512KB
thread.start()

// Subclass approach (Objective-C heritage)
class WorkerThread: Thread {
    override func main() {
        // Run until cancelled
        while !isCancelled {
            guard let task = dequeue() else {
                Thread.sleep(forTimeInterval: 0.01)
                continue
            }
            task()
        }
    }
}

let worker = WorkerThread()
worker.start()
// Later:
worker.cancel()
```

### Thread Properties

```swift
Thread.isMainThread          // Bool — check if on main thread
Thread.current               // current Thread object
Thread.current.name          // thread's name (useful for debugging)
Thread.current.isMainThread  // same as Thread.isMainThread

// Sleep
Thread.sleep(forTimeInterval: 0.5)
Thread.sleep(until: Date(timeIntervalSinceNow: 2.0))
```

### Thread-Local Storage

```swift
// Dictionary stored per-thread — not shared across threads
Thread.current.threadDictionary["requestID"] = "abc-123"
let id = Thread.current.threadDictionary["requestID"] as? String
```

### Performing on Specific Threads

```swift
// Perform selector on main thread
DispatchQueue.main.async { label.text = "Done" }  // prefer this

// Legacy ObjC pattern (still works in Swift)
someObject.performSelector(onMainThread: #selector(update), with: nil, waitUntilDone: false)

// Perform on background thread (creates a new thread each call — expensive)
someObject.performSelector(inBackground: #selector(doWork), with: nil)
```

## RunLoop

A `RunLoop` processes events (input sources, timers, port-based sources) on a thread. Every thread that uses Cocoa APIs gets a RunLoop; only the main thread's RunLoop runs automatically.

### Main RunLoop

The main RunLoop is started by UIApplicationMain/NSApplicationMain and drives the entire UI:

```swift
// Access main run loop
let mainRunLoop = RunLoop.main

// Modes control which sources/timers are active
RunLoop.Mode.default     // standard mode
RunLoop.Mode.common      // shared across common modes (default + tracking)
RunLoop.Mode.tracking    // during scroll — timers in .default won't fire here
```

### Keeping a Background Thread Alive

```swift
// Background threads' RunLoops must be manually started
class NetworkThread: Thread {
    var runLoopRef: CFRunLoop?

    override func main() {
        runLoopRef = CFRunLoopGetCurrent()

        // Add a dummy source to prevent RunLoop from exiting immediately
        let source = CFRunLoopSourceContext()
        var ctx = source
        let cfSource = CFRunLoopSourceCreate(nil, 0, &ctx)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSource, .defaultMode)

        // Run until cancelled
        while !isCancelled {
            RunLoop.current.run(mode: .default, before: .distantFuture)
        }

        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, .defaultMode)
    }

    func stop() {
        cancel()
        if let rl = runLoopRef { CFRunLoopStop(rl) }
    }
}
```

### CFRunLoopSource & Timers

```swift
// Schedule a timer on a specific RunLoop
let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
    print("tick")
}
RunLoop.current.add(timer, forMode: .default)

// Timer on main RunLoop (common mode fires during scrolling too)
RunLoop.main.add(timer, forMode: .common)

// Invalidate to stop
timer.invalidate()
```

### RunLoop in Tests

```swift
// Run the RunLoop for a fixed interval (useful in async tests without XCTestExpectation)
RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))

// Or use XCTestExpectation + RunLoop for legacy async tests
let expectation = XCTestExpectation(description: "network")
fetch { result in
    self.result = result
    expectation.fulfill()
}
RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))
XCTAssertNotNil(result)
```

## OperationQueue

`OperationQueue` builds on GCD to provide dependency management, priorities, and KVO-observable state.

### Basic Usage

```swift
let queue = OperationQueue()
queue.name = "com.myapp.operations"
queue.maxConcurrentOperationCount = 4  // 1 = serial, .defaultMaxConcurrentOperationCount = automatic

// Block operation
queue.addOperation {
    performWork()
}

// Named operation for debugging
let op = BlockOperation {
    performWork()
}
op.name = "FetchProfile"
queue.addOperation(op)

// Barrier-like: wait for all current, then run
queue.addBarrierBlock {
    consolidateResults()
}
```

### Dependency Graph

```swift
let fetch = BlockOperation { fetchData() }
let parse = BlockOperation { parseData() }
let save  = BlockOperation { saveData() }
let notify = BlockOperation { notifyUI() }

parse.addDependency(fetch)   // parse waits for fetch
save.addDependency(parse)    // save waits for parse
notify.addDependency(save)   // notify waits for save

queue.addOperations([fetch, parse, save, notify], waitUntilFinished: false)
```

### NSOperation Subclass (Async Operations)

For wrapping existing async callback APIs, subclass `Operation` and manage `isFinished`/`isExecuting` manually:

```swift
class AsyncOperation: Operation {
    private let lock = NSLock()

    private var _isExecuting = false
    override var isExecuting: Bool {
        get { lock.withLock { _isExecuting } }
        set {
            willChangeValue(forKey: "isExecuting")
            lock.withLock { _isExecuting = newValue }
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _isFinished = false
    override var isFinished: Bool {
        get { lock.withLock { _isFinished } }
        set {
            willChangeValue(forKey: "isFinished")
            lock.withLock { _isFinished = newValue }
            didChangeValue(forKey: "isFinished")
        }
    }

    override var isAsynchronous: Bool { true }

    override func start() {
        guard !isCancelled else {
            isFinished = true
            return
        }
        isExecuting = true
        execute()
    }

    func execute() {
        // Override in subclass — must call finish() when done
    }

    func finish() {
        isExecuting = false
        isFinished = true
    }
}

class NetworkOperation: AsyncOperation {
    let url: URL
    var result: Data?
    var error: Error?

    init(url: URL) { self.url = url }

    override func execute() {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            self?.result = data
            self?.error = error
            self?.finish()
        }.resume()
    }
}
```

### Cancellation

```swift
// Cancel all operations in queue
queue.cancelAllOperations()

// Check cancellation inside an operation
let op = BlockOperation {
    for chunk in chunks {
        guard !self.isCancelled else { return }
        process(chunk)
    }
}

// OperationQueue.main — serial queue on main thread
OperationQueue.main.addOperation {
    label.text = "Done"
}
```

### Priority

```swift
op.queuePriority = .veryHigh  // .veryLow, .low, .normal, .high, .veryHigh
op.qualityOfService = .userInitiated
```

## Locking Primitives

### NSLock

Simple mutual exclusion lock. Not reentrant — acquiring from the same thread deadlocks:

```swift
let lock = NSLock()

// Acquire/release manually
lock.lock()
defer { lock.unlock() }
criticalSection()

// With try — non-blocking
if lock.try() {
    defer { lock.unlock() }
    criticalSection()
}

// Named for debugging
lock.name = "com.myapp.cacheLock"
```

### NSRecursiveLock

Reentrant — the same thread can acquire multiple times (must unlock same number of times):

```swift
let lock = NSRecursiveLock()

func methodA() {
    lock.lock()
    defer { lock.unlock() }
    methodB()  // ✅ same thread re-acquires — no deadlock
}

func methodB() {
    lock.lock()
    defer { lock.unlock() }
    doWork()
}
```

Use when a locked function calls other functions that also need the lock (recursive or mutual-call scenarios).

### NSCondition

Combines a lock with a condition variable for wait/signal semantics:

```swift
let condition = NSCondition()
var isReady = false

// Producer
func produce() {
    condition.lock()
    isReady = true
    condition.signal()  // or .broadcast() for multiple waiters
    condition.unlock()
}

// Consumer
func consume() {
    condition.lock()
    while !isReady {
        condition.wait()  // releases lock, suspends thread, re-acquires on wake
    }
    doWork()
    condition.unlock()
}
```

**Always use `while` (not `if`) to guard `wait()` — spurious wakeups are possible.**

### NSConditionLock

Lock with an integer condition — acquires only when the condition matches:

```swift
let conditionLock = NSConditionLock(condition: 0)

// Thread 1: runs when condition == 0, sets condition to 1 when done
conditionLock.lock(whenCondition: 0)
doPhase1()
conditionLock.unlock(withCondition: 1)

// Thread 2: runs when condition == 1, sets condition to 2 when done
conditionLock.lock(whenCondition: 1)
doPhase2()
conditionLock.unlock(withCondition: 2)
```

Useful for pipelining stages that must run in sequence.

### os_unfair_lock (Swift 5.9+)

Lowest-overhead lock available. Non-reentrant, non-blocking (spin-based for short critical sections):

```swift
import os

// Must be heap-allocated (class or pointer) — not on stack in Swift 5.9+
final class UnfairLockProtected<T> {
    private var lock = OSAllocatedUnfairLock()
    private var value: T

    init(_ value: T) { self.value = value }

    func withLock<R>(_ body: (inout T) throws -> R) rethrows -> R {
        try lock.withLock { try body(&value) }
    }
}

let counter = UnfairLockProtected(0)
counter.withLock { $0 += 1 }
```

**Warning:** Never use `os_unfair_lock` across a `pthread_mutex_t` boundary; never unlock from a different thread than locked it.

### Lock Performance Comparison

| Lock | Overhead | Reentrant | Blocking | Use Case |
|------|----------|-----------|----------|----------|
| `OSAllocatedUnfairLock` | ~10ns | No | Yes (adaptive) | Hottest paths, short sections |
| `NSLock` | ~25ns | No | Yes | General purpose |
| `NSRecursiveLock` | ~35ns | Yes | Yes | Recursive/mutual-call patterns |
| `DispatchSemaphore(1)` | ~50ns | No | Yes | Semaphore semantics |
| Actor | ~100ns | Reentrant (task-level) | Suspends (not blocks) | Prefer in Swift Concurrency |
| `NSCondition` | ~40ns | No | Yes (waitable) | Producer-consumer |

## AtomicInt / Atomics

Swift doesn't expose C11 atomics directly, but you can use:

```swift
// Swift Atomics package (Apple)
// import Atomics

var counter = ManagedAtomic<Int>(0)
counter.wrappingIncrement(ordering: .relaxed)
let value = counter.load(ordering: .acquiring)

// Older pattern: OSAtomicIncrement32 (deprecated)
// Use swift-atomics package instead

// For simple flags, @_silgen_name wrapping works but is not recommended.
// Easiest: use DispatchQueue.sync or actor for reference-semantic safety.
```

## Migration Guide: Legacy → Modern

| Legacy | Modern Replacement |
|--------|--------------------|
| `Thread` | `Task.detached` or `Task` |
| `RunLoop` (keeping thread alive) | `Task` (no need for explicit RunLoop) |
| `OperationQueue` | `TaskGroup` with structured concurrency |
| `NSOperation` async subclass | `async/await` function |
| `NSLock` / `NSRecursiveLock` | `actor` |
| `NSCondition` / `NSConditionLock` | `actor` + `AsyncStream` |
| `DispatchGroup` | `async let` / `TaskGroup` |
| Completion handlers | `async throws` functions |
| `NotificationCenter` observer | `.publisher(for:)` + `.values` |

### Migration Strategy

1. **Wrap first**: wrap existing callback APIs in `withCheckedContinuation` before refactoring callers
2. **Isolate actors**: replace `NSLock`-guarded classes with `actor`
3. **Replace OperationQueues**: convert `NSOperation` dependencies to structured concurrency
4. **Migrate bottom-up**: migrate leaf operations first (no dependencies), then callers
