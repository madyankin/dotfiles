# Combine Deep Dive

Complete reference for Combine: publishers, subscribers, operators, schedulers, backpressure, error handling, custom publishers, and interoperability with Swift Concurrency.

## Core Concepts

Combine is a declarative reactive framework for processing values over time (iOS 13+, macOS 10.15+).

```
[Publisher] → [Operator] → [Operator] → [Subscriber]
  (source)   (transform)  (transform)   (sink/assign)
```

**Key types:**
- `Publisher<Output, Failure>` — emits zero or more values, then completes or fails
- `Subscriber<Input, Failure>` — receives values from a publisher
- `Cancellable` — token returned by subscription; cancel when done
- `Subject` — publisher you can imperatively push values into
- `Scheduler` — controls what thread/queue operators and subscribers run on

## Publishers

### Built-in Publishers

```swift
import Combine

// Single value then complete
Just(42).sink { print($0) }  // 42

// Sequence of values
[1, 2, 3].publisher.sink { print($0) }

// Fail immediately
Fail<Int, URLError>(error: URLError(.badURL))

// Never emit, never complete
Empty<Int, Never>()

// Future — wraps a single async callback
let future = Future<User, Error> { promise in
    fetchUser { result in promise(result) }
}

// Timer publisher
Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()
    .sink { date in print("tick: \(date)") }
    .store(in: &cancellables)

// URLSession
URLSession.shared.dataTaskPublisher(for: url)
    .map(\.data)
    .decode(type: User.self, decoder: JSONDecoder())

// NotificationCenter
NotificationCenter.default
    .publisher(for: UIApplication.didBecomeActiveNotification)
    .sink { _ in refreshData() }

// KeyPath publisher (KVO-compatible types)
object.publisher(for: \.someProperty)
    .sink { newValue in handleChange(newValue) }
```

## Subjects

Subjects let you imperatively push values into a Combine pipeline.

### PassthroughSubject

No stored value; new subscribers receive only future values:

```swift
let subject = PassthroughSubject<String, Never>()

let subscription = subject.sink { print("Received: \($0)") }

subject.send("hello")   // prints "Received: hello"
subject.send("world")   // prints "Received: world"
subject.send(completion: .finished)

// Common use: bridging delegate/callback patterns
class LocationBridge: NSObject, CLLocationManagerDelegate {
    let locationPublisher = PassthroughSubject<CLLocation, Never>()

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        locations.forEach { locationPublisher.send($0) }
    }
}
```

### CurrentValueSubject

Stores the current value; new subscribers receive it immediately:

```swift
let isLoading = CurrentValueSubject<Bool, Never>(false)

// Access current value
print(isLoading.value)  // false

// Send new value
isLoading.send(true)
isLoading.value = true  // equivalent

// Subscribe
isLoading.sink { loading in
    spinner.isHidden = !loading
}.store(in: &cancellables)
```

## Operators

### Transforming Values

```swift
publisher
    .map { $0 * 2 }                          // transform each value
    .compactMap { Int($0) }                   // filter nil, unwrap optionals
    .flatMap { id in fetchUser(id: id) }      // map to inner publisher (switchMap-like)
    .flatMap(maxPublishers: .max(3)) { ... }  // limit concurrent inner publishers
    .scan(0) { acc, next in acc + next }      // running accumulator
    .tryMap { try parse($0) }                 // throwing transform
    .mapError { AppError.network($0) }        // transform error type
```

### Filtering

```swift
publisher
    .filter { $0 > 0 }                        // only pass values matching predicate
    .removeDuplicates()                        // only emit when value changes
    .removeDuplicates(by: { $0.id == $1.id }) // custom equality
    .first()                                   // only first value, then complete
    .first(where: { $0 > 10 })               // first matching value
    .dropFirst(3)                              // skip first N values
    .drop(while: { $0 < 10 })                // skip until predicate false
    .prefix(5)                                 // complete after N values
    .prefix(while: { $0 < 100 })             // complete when predicate false
```

### Timing

```swift
publisher
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)   // wait for quiet period
    .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)  // rate limit
    .delay(for: .seconds(2), scheduler: DispatchQueue.main)       // delay each value
    .timeout(.seconds(10), scheduler: DispatchQueue.main)         // fail if no value
    .measureInterval(using: RunLoop.main)                          // emit time between values
```

### Combining Publishers

```swift
// Merge — combine multiple publishers of same type
Publishers.Merge(publisher1, publisher2)
    .sink { print($0) }

// Zip — pair values (waits for both)
Publishers.Zip(userPublisher, postsPublisher)
    .sink { user, posts in showProfile(user: user, posts: posts) }

// CombineLatest — emit latest of each when any changes
Publishers.CombineLatest(usernamePublisher, passwordPublisher)
    .map { username, password in username.count >= 3 && password.count >= 8 }
    .assign(to: \.isEnabled, on: loginButton)

// Append/prepend
publisher.prepend(0, 1, 2)     // emit 0, 1, 2 before publisher values
publisher.append(99, 100)      // emit 99, 100 after publisher completes
```

### Error Handling

```swift
publisher
    .catch { error in               // replace failed publisher with fallback
        Just(defaultValue)
    }
    .catch { error -> AnyPublisher<User, Never> in
        errorSubject.send(error)
        return Just(User.empty).eraseToAnyPublisher()
    }
    .retry(3)                       // retry on failure up to N times
    .replaceError(with: defaultValue)  // replace error with value, never fails
    .assertNoFailure()              // crash in debug if publisher fails (Never error)
```

### Switching

```swift
// switchToLatest — when upstream emits a publisher, subscribe to it, cancel previous
searchTextField.textPublisher
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .map { text in searchAPI.search(query: text) }  // Publisher<Publisher<Results, Error>, Never>
    .switchToLatest()  // cancel previous search, subscribe to latest
    .catch { _ in Just([]) }
    .receive(on: RunLoop.main)
    .assign(to: \.results, on: viewModel)
```

## Schedulers

Schedulers control **where** (which thread/queue) operators execute.

```swift
// subscribe(on:) — where upstream work is performed (subscription side)
// receive(on:)   — where downstream receives values (output side)

URLSession.shared.dataTaskPublisher(for: url)
    .subscribe(on: DispatchQueue.global(qos: .background))  // network on bg thread
    .map { try JSONDecoder().decode(User.self, from: $0.data) }
    .receive(on: DispatchQueue.main)  // deliver to subscriber on main thread
    .sink(
        receiveCompletion: { _ in spinner.stopAnimating() },
        receiveValue: { user in updateUI(with: user) }
    )
    .store(in: &cancellables)
```

### Available Schedulers

| Scheduler | Thread | Use Case |
|-----------|--------|----------|
| `DispatchQueue.main` | Main thread | UI updates |
| `DispatchQueue.global(qos:)` | Thread pool | Background work |
| `RunLoop.main` | Main thread (RunLoop-aware) | Timer publishers, UI |
| `ImmediateScheduler` | Caller's thread | Testing, synchronous |
| `OperationQueue.main` | Main thread | Legacy compatibility |

```swift
// RunLoop vs DispatchQueue.main
// Use RunLoop.main for Timer.publish and other RunLoop-dependent sources
Timer.publish(every: 1, on: .main, in: .common)
    .receive(on: RunLoop.main)  // ✅ correct for RunLoop sources

// Use DispatchQueue.main for most cases
urlSession.publisher
    .receive(on: DispatchQueue.main)  // ✅ correct for network results
```

## Subscribers

### sink

Most common subscriber — closure-based:

```swift
publisher
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished: print("Done")
            case .failure(let error): handle(error)
            }
        },
        receiveValue: { value in
            process(value)
        }
    )
    .store(in: &cancellables)

// Non-failing publisher — single closure
publisher
    .sink { value in process(value) }
    .store(in: &cancellables)
```

### assign

Binds publisher output directly to a property (no error handling — publisher must be `Never` failure):

```swift
// assign(to:on:) — creates strong reference to object (retain cycle risk with self)
publisher
    .assign(to: \.title, on: titleLabel)  // ⚠️ strongly retains titleLabel

// assign(to:) — for @Published properties, avoids retain cycles
viewModel.$isLoading
    .assign(to: &$localLoadingState)  // tied to this object's lifetime, no retain cycle
```

### Custom Subscriber

```swift
class PrintSubscriber<Input, Failure: Error>: Subscriber {
    func receive(subscription: Subscription) {
        subscription.request(.unlimited)  // request all values
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        print("Received: \(input)")
        return .none  // don't request more (unlimited already requested)
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        print("Completed: \(completion)")
    }
}

publisher.subscribe(PrintSubscriber())
```

## Backpressure

Backpressure is a mechanism for subscribers to signal how many values they can handle.

```swift
// Subscribers.Demand controls how many values to receive
// .unlimited — receive everything
// .max(n) — receive up to n more
// .none — receive nothing more right now

class ThrottledSubscriber: Subscriber {
    var subscription: Subscription?

    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))  // only request 1 at a time
    }

    func receive(_ input: String) -> Subscribers.Demand {
        process(input)
        // After processing, request 1 more
        return .max(1)  // incremental backpressure
    }
}
```

### Built-in Backpressure Operators

```swift
// Buffer — absorb bursts, apply backpressure to upstream
publisher
    .buffer(size: 100, prefetch: .byRequest, whenFull: .dropOldest)
    .sink { process($0) }

// collect — buffer N items then emit as array
publisher
    .collect(10)  // emit arrays of 10
    .sink { batch in processBatch(batch) }

// collect with time window
publisher
    .collect(.byTimeOrCount(RunLoop.main, .seconds(1), 100))
    .sink { batch in processBatch(batch) }
```

## Memory Management

```swift
class ViewModel {
    var cancellables = Set<AnyCancellable>()  // holds subscriptions alive

    func setup() {
        // .store(in:) ties cancellable lifetime to this Set
        publisher
            .sink { [weak self] value in
                self?.handleValue(value)  // weak self prevents retain cycle
            }
            .store(in: &cancellables)
    }

    deinit {
        // cancellables cleared → all subscriptions cancelled automatically
    }
}
```

**Rules:**
1. Always store `AnyCancellable` — subscriptions auto-cancel when the token is deallocated
2. Use `[weak self]` in `sink` closures that capture the owning object
3. Prefer `assign(to: &$published)` over `assign(to:on:self)` to avoid retain cycles

## AnyPublisher (Type Erasure)

```swift
// Expose only AnyPublisher from APIs — hide implementation details
func fetchUser(id: String) -> AnyPublisher<User, APIError> {
    URLSession.shared.dataTaskPublisher(for: userURL(id))
        .map(\.data)
        .decode(type: User.self, decoder: JSONDecoder())
        .mapError { APIError.network($0) }
        .eraseToAnyPublisher()  // hide concrete publisher type
}
```

## Custom Publishers

```swift
// Publisher that emits a value after a delay, with cancellation
struct DelayedPublisher<Output>: Publisher {
    typealias Failure = Never
    let value: Output
    let delay: TimeInterval

    func receive<S: Subscriber>(subscriber: S)
    where S.Input == Output, S.Failure == Never {
        let subscription = DelayedSubscription(
            subscriber: subscriber,
            value: value,
            delay: delay
        )
        subscriber.receive(subscription: subscription)
    }
}

class DelayedSubscription<S: Subscriber>: Subscription
where S.Failure == Never {
    private var subscriber: S?
    private var workItem: DispatchWorkItem?
    private let value: S.Input
    private let delay: TimeInterval

    init(subscriber: S, value: S.Input, delay: TimeInterval) {
        self.subscriber = subscriber
        self.value = value
        self.delay = delay
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0, let subscriber else { return }
        let item = DispatchWorkItem { [weak self] in
            guard let self, let subscriber = self.subscriber else { return }
            _ = subscriber.receive(self.value)
            subscriber.receive(completion: .finished)
            self.subscriber = nil
        }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancel() {
        workItem?.cancel()
        subscriber = nil
    }
}
```

## Combine + Swift Concurrency Interoperability

### Publisher → AsyncSequence

```swift
// Convert any publisher to AsyncSequence (Swift 5.5+)
let stream = publisher.values  // AsyncPublisher<P>

for await value in publisher.values {
    process(value)
}

// With error handling
for try await value in failablePublisher.values {
    process(value)
}
```

### async/await → Publisher

```swift
// Wrap async function in a Deferred+Future
func asyncToPublisher<T>(_ operation: @escaping () async throws -> T)
-> AnyPublisher<T, Error> {
    Deferred {
        Future { promise in
            Task {
                do { promise(.success(try await operation())) }
                catch { promise(.failure(error)) }
            }
        }
    }.eraseToAnyPublisher()
}

// Usage
asyncToPublisher { try await api.fetchUser() }
    .receive(on: .main)
    .sink(receiveCompletion: { _ in }, receiveValue: { show($0) })
    .store(in: &cancellables)
```

### Which to Use?

| Situation | Use |
|-----------|-----|
| New code on iOS 15+ | Swift Concurrency (async/await) |
| Existing Combine pipelines | Keep Combine, interop with `.values` |
| SwiftUI `@Published`, `ObservableObject` | Combine (SwiftUI built on it) |
| Complex operator chains (debounce, zip, etc.) | Combine operators are more expressive |
| Single async operations | async/await with `try await` |
| Event streams (user input, notifications) | Either: AsyncStream or Combine |

## Common Patterns

### Form Validation

```swift
@MainActor
class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published private(set) var isLoginEnabled = false

    init() {
        Publishers.CombineLatest($username, $password)
            .map { username, password in
                username.count >= 3 && password.count >= 8
            }
            .assign(to: &$isLoginEnabled)
    }
}
```

### Search with Debounce

```swift
@Published var searchText = ""

$searchText
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .removeDuplicates()
    .filter { !$0.isEmpty }
    .flatMap { [weak self] query -> AnyPublisher<[Result], Never> in
        self?.searchAPI.search(query: query)
            .catch { _ in Just([]) }
            .eraseToAnyPublisher() ?? Just([]).eraseToAnyPublisher()
    }
    .receive(on: RunLoop.main)
    .assign(to: &$results)
```

### Retry with Exponential Backoff

```swift
extension Publisher {
    func retryWithBackoff(
        maxRetries: Int,
        initialDelay: TimeInterval = 0.5
    ) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            guard maxRetries > 0 else {
                return Fail(error: error).eraseToAnyPublisher()
            }
            return Just(())
                .delay(for: .seconds(initialDelay), scheduler: DispatchQueue.global())
                .flatMap { _ in
                    self.retryWithBackoff(
                        maxRetries: maxRetries - 1,
                        initialDelay: initialDelay * 2
                    )
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
```
