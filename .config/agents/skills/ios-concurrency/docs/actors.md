# Actors & Sendable Deep Dive

Complete reference for Swift actors, actor isolation, MainActor, global actors, Sendable conformance, and interoperability with Objective-C.

## Actor Model Fundamentals

An actor is a reference type with **serialized access to its mutable state** — only one task can execute actor-isolated code at a time, but without explicit locking. The Swift runtime enforces this through the type system.

```
Traditional approach:          Actor approach:
  Thread A ──┐                   Task A ──┐
  Thread B ──┤──► Lock ──► State   Task B ──┤──► Actor mailbox ──► State (serial)
  Thread C ──┘                   Task C ──┘
                                         (tasks suspend, not threads)
```

## Defining Actors

```swift
actor Counter {
    private(set) var value: Int = 0

    func increment() {
        value += 1
    }

    func incrementBy(_ amount: Int) -> Int {
        value += amount
        return value
    }

    // nonisolated — can be called without await
    // Must NOT access mutable actor state
    nonisolated var label: String { "Counter" }
    nonisolated func readonlyDescription() -> String { "A counter" }
}

let counter = Counter()
await counter.increment()          // must await
let v = await counter.incrementBy(5)
print(counter.label)               // no await needed — nonisolated
```

### What's Isolated vs nonisolated

| Access | Requires await? | Can access mutable state? |
|--------|-----------------|--------------------------|
| Actor method (default) | Yes | Yes |
| `nonisolated` method | No | No (compile error) |
| Actor property (var) | Yes | Yes |
| `nonisolated let` property | No | Yes (immutable) |
| `nonisolated` computed property | No | No mutable state |

## Actor Reentrancy

Actors are **reentrant**: when a task suspends inside an actor method (at `await`), other tasks can run on the actor. The actor's state may change across a suspension point.

```swift
actor Inventory {
    var stock: Int = 10

    func purchase() async -> Bool {
        guard stock > 0 else { return false }

        // ⚠️ SUSPENSION POINT — another purchase() can run between guard and deduction
        await recordPurchaseInDB()

        stock -= 1  // stock could already be 0 here!
        return true
    }

    // ✅ Fix: complete synchronous state mutations before suspending
    func purchaseSafe() async -> Bool {
        guard stock > 0 else { return false }
        stock -= 1                  // mutate atomically before suspension
        await recordPurchaseInDB()  // now it's safe to suspend
        return true
    }

    // ✅ Alternative: re-check after suspension
    func purchaseWithRecheck() async -> Bool {
        guard stock > 0 else { return false }
        await recordPurchaseInDB()
        guard stock > 0 else {      // re-check after suspension
            await refundPurchaseInDB()
            return false
        }
        stock -= 1
        return true
    }
}
```

### Rules for Reentrancy-Safe Design

1. **Mutate state before suspending** when the mutation and the subsequent async work should be atomic from the caller's perspective
2. **Re-check invariants after every `await`** if you must suspend before mutating
3. **Don't assume invariants hold across `await`** — treat each `await` as a potential interleaving point

## Actor Isolation Boundaries

### Crossing Into an Actor

Any access to actor-isolated state from **outside** the actor requires `await`:

```swift
actor Store {
    var items: [Item] = []
    func add(_ item: Item) { items.append(item) }
}

// External access
let store = Store()
await store.add(Item())           // ✅ await required
let count = await store.items.count  // ✅ await required

// ❌ Compile error — cannot access without await
let count = store.items.count
```

### Crossing Out of an Actor

Calling non-isolated async functions from inside an actor temporarily leaves the actor's isolation:

```swift
actor DataManager {
    var cache: [String: Data] = [:]

    func refresh(key: String) async throws {
        // We leave actor isolation to perform network I/O
        let data = try await URLSession.shared.data(from: url(for: key)).0
        // We're back on the actor here — safe to mutate cache
        cache[key] = data
    }
}
```

### Sendable Requirement at Isolation Boundaries

Values crossing actor isolation boundaries must be `Sendable`:

```swift
actor Processor {
    func process(_ request: Request) { }  // Request must be Sendable
}

// ✅ Sendable struct — safe to cross boundaries
struct Request: Sendable {
    let id: UUID
    let payload: Data
}

// ❌ Not Sendable — mutable class, could be mutated from multiple actors
class MutableRequest {  // no Sendable conformance
    var id: UUID = UUID()
}
```

## Sendable

`Sendable` is a marker protocol indicating a type is safe to share across concurrency domains (actors, tasks, threads).

### Automatic Sendable Conformance

```swift
// Structs with all-Sendable stored properties: automatically Sendable
struct Point: Sendable {   // or just `struct Point` — synthesized
    let x: Double
    let y: Double
}

// Enums with Sendable associated values: automatically Sendable
enum Result<T: Sendable>: Sendable {
    case success(T)
    case failure(Error)  // Error is Sendable
}

// Actors are implicitly Sendable
actor MyActor { }  // always Sendable

// Final classes with all immutable Sendable properties
final class Token: Sendable {
    let value: String  // immutable — safe
    init(_ value: String) { self.value = value }
}
```

### @unchecked Sendable

Use when you guarantee thread safety yourself (e.g., via a lock), but the compiler can't verify it:

```swift
// Manually synchronized — safe but compiler can't prove it
final class ThreadSafeCache: @unchecked Sendable {
    private var data: [String: Any] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Any? {
        lock.withLock { data[key] }
    }

    func set(_ value: Any, for key: String) {
        lock.withLock { data[key] = value }
    }
}
```

**Warning:** `@unchecked Sendable` defeats the type system — document your thread safety invariants clearly.

### @Sendable Closures

Closures that cross isolation boundaries must be `@Sendable`:

```swift
// Task requires @Sendable closure — captures are checked for Sendable
Task {  // this closure is @Sendable
    await someActor.work()
}

// ✅ Captured value type — fine
var counter = 0
Task { counter += 1 }  // captures copy of counter

// ❌ Captured reference type — must be Sendable
class NotSendable { var x = 0 }
let obj = NotSendable()
Task { obj.x += 1 }  // ⚠️ Warning: capture of non-Sendable type
```

### Common Sendable Types

| Type | Sendable? | Reason |
|------|-----------|--------|
| `Int`, `String`, `Bool`, etc. | ✅ | Value types |
| `struct` (all Sendable fields) | ✅ | Value semantics |
| `enum` (all Sendable cases) | ✅ | Value semantics |
| `actor` | ✅ | Enforces isolation |
| Immutable `final class` | ✅ (conditional) | No mutation |
| `class` with mutable state | ❌ | Data race risk |
| `[T] where T: Sendable` | ✅ | Conditional |
| `UIView`, `NSObject` subclasses | ❌ | Main-thread only |
| Closures | `@Sendable` if declared |  |

## MainActor

`@MainActor` is a global actor that serializes execution on the main thread. It replaces `DispatchQueue.main.async` in modern Swift.

### Annotating Types

```swift
// Entire class runs on main thread
@MainActor
class ViewController: UIViewController {
    var items: [Item] = []  // all access serialized on main thread

    func updateItems(_ newItems: [Item]) {
        items = newItems
        tableView.reloadData()
    }
}

// Entire ViewModel — all @Published mutations on main
@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false

    func loadPosts() async {
        isLoading = true
        posts = try! await api.fetchPosts()  // hops off main, returns to main
        isLoading = false
    }
}
```

### Annotating Individual Methods and Properties

```swift
class DataProcessor {
    // Only this method is MainActor-isolated
    @MainActor
    func updateProgressBar(to value: Double) {
        progressBar.progress = Float(value)
    }

    func processInBackground() async {
        for chunk in chunks {
            let processed = await process(chunk)
            await updateProgressBar(to: processed.progress)  // hops to main
        }
    }
}
```

### Hopping to MainActor

```swift
// From any async context
await MainActor.run {
    label.text = "Done"
    spinner.stopAnimating()
}

// Using the type annotation
@MainActor func updateUI() {
    label.text = "Done"
}

// Call from non-MainActor async context
await updateUI()

// MainActor.assertIsolated() — crash if not on main (useful for debugging)
func mustBeOnMain() {
    MainActor.assertIsolated()
    label.text = "Verified on main"
}
```

### MainActor + UIKit/SwiftUI

```swift
// UIKit: most UIKit APIs require main thread — annotate view controllers
@MainActor
class MyViewController: UIViewController {
    // All methods implicitly @MainActor
}

// SwiftUI: @StateObject/@ObservedObject with @MainActor ViewModel
struct ContentView: View {
    @StateObject var vm = FeedViewModel()  // @MainActor class

    var body: some View {
        List(vm.posts) { post in PostRow(post: post) }
            .task { await vm.loadPosts() }  // @MainActor context from task
    }
}
```

## Global Actors

You can define custom global actors for subsystems that need their own isolated executor (e.g., database actor, rendering actor):

```swift
// Define a global actor
@globalActor
actor DatabaseActor {
    static let shared = DatabaseActor()
}

// Use it like @MainActor
@DatabaseActor
class DatabaseManager {
    func query(_ sql: String) async -> [Row] { ... }
}

@DatabaseActor
func fetchUser(id: String) async -> User { ... }

// Calling code must await
let user = await fetchUser(id: "42")
```

### When to Use Global Actors

- **Singleton subsystems** that need serial access (database, rendering, audio)
- **Replacing serial DispatchQueues** with type-system-enforced isolation
- **Testing** — inject a different global actor conformance in tests

## Actor Inheritance

Actors **cannot inherit from other actors** — they are always final. If you need shared behavior, use protocols:

```swift
// ❌ Not allowed
actor SubActor: BaseActor { }

// ✅ Use protocols instead
protocol CacheProtocol: Actor {
    func get(key: String) async -> Data?
    func set(key: String, data: Data) async
}

actor MemoryCache: CacheProtocol {
    func get(key: String) async -> Data? { ... }
    func set(key: String, data: Data) async { ... }
}

actor DiskCache: CacheProtocol {
    func get(key: String) async -> Data? { ... }
    func set(key: String, data: Data) async { ... }
}
```

## Objective-C Interoperability

### Calling ObjC from Swift Actors

```swift
// ObjC completion handlers are automatically bridged to async in Swift
// No special handling needed for most Foundation APIs

actor NetworkLayer {
    func fetchData() async throws -> Data {
        // URLSession is safe to call from actors — it returns on appropriate thread
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
```

### Exposing Swift Actors to ObjC

Actors **cannot be directly exposed to ObjC** — actors are Swift-only. Bridge with a wrapper:

```swift
// ❌ Cannot mark actor @objc
// @objc actor MyActor { }  // compile error

// ✅ Bridge with a non-actor class
@objc class ActorBridge: NSObject {
    private let actor = MyActor()

    @objc func doWork(completion: @escaping (Result) -> Void) {
        Task {
            let result = await actor.work()
            completion(result)
        }
    }
}
```

### @MainActor with ObjC

UIViewController and other UIKit classes are implicitly `@MainActor` in Swift. When subclassing in Swift:

```swift
// UIViewController is treated as @MainActor
// Your subclass inherits this
class MyVC: UIViewController {
    // All methods implicitly @MainActor — can access UIKit without DispatchQueue.main
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            let data = try await fetchData()  // leaves main
            label.text = data.title           // back on @MainActor — safe
        }
    }
}
```

## Actor Isolation & Protocol Conformances

```swift
protocol Updatable {
    func update() async
}

actor MyActor: Updatable {
    func update() async {
        // implicitly isolated to MyActor
    }
}

// Conforming a @MainActor type to a protocol
@MainActor
class MyViewModel: Updatable {
    func update() async {
        // implicitly @MainActor
        tableView.reloadData()
    }
}

// Non-isolated protocol conformance
actor Processor: CustomStringConvertible {
    // nonisolated synthesized for non-async protocol requirements
    nonisolated var description: String { "Processor" }
}
```

## Diagnosing Actor Issues

### Actor Contention

If many tasks are waiting for the same actor, it becomes a bottleneck:

```swift
// ❌ High contention — all requests funnel through one actor
actor RequestLogger {
    var log: [String] = []
    func record(_ entry: String) { log.append(entry) }
}
// Called for every network request — serialized, potential bottleneck

// ✅ Reduce actor contention with batching
actor RequestLogger {
    var log: [String] = []

    func recordBatch(_ entries: [String]) {
        log.append(contentsOf: entries)
    }
}

// Or use non-actor solutions for high-frequency writes (e.g., OSLog, os_unfair_lock)
```

### Instruments: Swift Concurrency Template

- **Actor contention**: shows tasks waiting for actors — identify hot actors
- **Task creation**: visualize task trees and lifetimes
- **Cooperative thread pool**: see if threads are being blocked

### Strict Concurrency Checking

Enable maximum checking in Xcode:
**Build Settings → Swift Compiler - Upcoming Features → Strict Concurrency Checking → Complete**

This surfaces Sendable violations and isolation mismatches at compile time — far easier to fix than runtime data races.

```swift
// With complete concurrency checking, this warns:
class MyVC: UIViewController {
    func loadData() {
        Task {
            let data = await fetch()
            // ⚠️ Warning: expression is 'async' but is not marked with 'await'
            //    or: mutation of captured var in concurrently-executing code
            self.items = data  // fine if class is @MainActor
        }
    }
}
```

## Swift 6 Concurrency (Data Race Safety)

Swift 6 enables **complete concurrency checking by default** — all data races become compile errors:

```swift
// Swift 6: This is a compile error, not a warning
var shared: Int = 0
Task { shared += 1 }  // ❌ Mutation of captured var in concurrent context
Task { shared += 1 }  // ❌ Same issue

// Swift 6 fix:
actor SafeCounter {
    var value = 0
    func increment() { value += 1 }
}
```

Migration path: Enable strict concurrency incrementally with `SWIFT_STRICT_CONCURRENCY` build setting.
