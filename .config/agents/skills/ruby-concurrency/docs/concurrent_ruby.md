# concurrent-ruby Gem

The `concurrent-ruby` gem provides production-ready concurrency primitives inspired by Erlang, Clojure, Scala, Go, Java, and JavaScript. It works consistently across MRI, JRuby, and TruffleRuby.

```ruby
gem 'concurrent-ruby'
require 'concurrent-ruby'

# Extended features (actors, channels, etc.)
require 'concurrent-ruby-ext'  # optional C extensions for MRI performance
```

---

## Promises (Futures / Async Pipelines)

`Concurrent::Promises` is the unified API for asynchronous values:

```ruby
# Future: async computation
future = Concurrent::Promises.future { slow_computation }
future.resolved?   # => false (maybe)
future.value       # blocks until done, returns nil on error
future.value!      # blocks, raises on error
future.reason      # the exception, if failed

# Chaining
Concurrent::Promises
  .future { fetch_user(id) }
  .then   { |user| enrich_user(user) }
  .then   { |user| render(user) }
  .rescue { |e| default_response }
  .value!

# Parallel zip
a = Concurrent::Promises.future { compute_a }
b = Concurrent::Promises.future { compute_b }
Concurrent::Promises.zip(a, b).value!  # => [result_a, result_b]

# Any (first resolved wins)
Concurrent::Promises.any(a, b).value!

# Schedule for later
Concurrent::Promises.schedule(5) { puts "5 seconds later" }

# Delay (lazy—doesn't run until .value or .then is called)
lazy = Concurrent::Promises.delay { expensive_work }
lazy.value  # triggers execution now
```

### Error Handling in Chains

```ruby
Concurrent::Promises
  .future { may_fail }
  .then   { |v| process(v) }        # skipped if previous failed
  .rescue { |e| handle_error(e) }   # runs if any previous step failed
  .then   { |v| finalize(v) }       # runs after rescue
  .value!
```

### Custom Thread Pool

```ruby
pool = Concurrent::FixedThreadPool.new(4)

future = Concurrent::Promises.future_on(pool) { work }
Concurrent::Promises.zip_futures_on(pool, f1, f2).value!
```

---

## Thread Pools

### FixedThreadPool

Maintains exactly N threads. Tasks queue when all threads are busy.

```ruby
pool = Concurrent::FixedThreadPool.new(10)

pool.post { do_work }
pool.post(arg1, arg2) { |a, b| do_work(a, b) }

pool.running?
pool.shutdown          # no new tasks accepted; finishes existing
pool.kill              # immediate stop (tasks may be lost)
pool.wait_for_termination(30)  # timeout in seconds
pool.completed_task_count
pool.queue_length
```

### CachedThreadPool

Grows on demand, shrinks when threads are idle (default 60s idle timeout):

```ruby
pool = Concurrent::CachedThreadPool.new
pool.post { short_task }
```

Good for bursty workloads. Bad for steady-state high-load (thread churn).

### TimerTask

Runs a task repeatedly on a schedule:

```ruby
task = Concurrent::TimerTask.new(execution_interval: 30) do
  flush_metrics
end

task.add_observer do |time, result, error|
  logger.error(error) if error
end

task.execute
task.running?   # => true
task.shutdown
```

---

## Thread-Safe Data Structures

### Concurrent::Map (recommended for concurrent access)

Better performance than `Hash + Mutex` for most concurrent patterns:

```ruby
map = Concurrent::Map.new

map[:key] = "value"
map[:key]                    # => "value"
map.fetch(:key, "default")
map.fetch_or_store(:key) { compute_default }  # atomic compute-if-absent
map.put_if_absent(:key, value)                # atomic insert-if-absent
map.replace_if_exists(:key, new_value)
map.delete(:key)
map.each_pair { |k, v| }
map.size
```

### Concurrent::Array / Concurrent::Hash

Wrap Ruby's built-in structures with a Mutex. Less performant than `Concurrent::Map` but familiar interface:

```ruby
arr  = Concurrent::Array.new
hash = Concurrent::Hash.new
```

### Atomic Types

```ruby
# AtomicBoolean
flag = Concurrent::AtomicBoolean.new(false)
flag.value         # => false
flag.true?         # => false
flag.make_true     # sets to true, returns whether it changed
flag.make_false
flag.toggle        # flips, returns old value

# AtomicFixnum (integer counter)
counter = Concurrent::AtomicFixnum.new(0)
counter.increment          # atomic +=1, returns new value
counter.decrement          # atomic -=1
counter.update { |v| v + 5 }  # CAS loop
counter.value

# AtomicReference (any object)
ref = Concurrent::AtomicReference.new(nil)
ref.set("hello")
ref.get
ref.get_and_set("world")        # returns old, sets new
ref.compare_and_set("world", "!") # true if swapped
```

### Atom (functional state management)

`Atom` applies a function atomically, retrying on conflict (optimistic concurrency):

```ruby
state = Concurrent::Atom.new({ count: 0, items: [] })

# swap retries the block until no conflict
state.swap do |current|
  current.merge(count: current[:count] + 1)
end

state.reset({ count: 0, items: [] })
state.value   # current state
```

Suitable for shared, complex state where updates are pure functions.

---

## Semaphore

Limits concurrent access to a resource pool:

```ruby
sem = Concurrent::Semaphore.new(5)  # 5 permits

threads = 20.times.map do
  Thread.new do
    sem.acquire
    begin
      use_limited_resource
    ensure
      sem.release
    end
  end
end
threads.each(&:join)
```

---

## Actors (Experimental)

Actors are lightweight agents that process messages sequentially from a mailbox, running on shared thread pools:

```ruby
require 'concurrent-ruby'

class Counter < Concurrent::Actor::RestartingContext
  def initialize
    @count = 0
  end

  def on_message(msg)
    case msg
    when :increment then @count += 1
    when :value     then @count
    end
  end
end

counter = Counter.spawn(:my_counter)
counter.tell(:increment)
counter.tell(:increment)
counter.ask(:value).value!  # => 2
```

**Note**: Actors are not suitable for blocking I/O (they'd starve the thread pool). Use Promises + FixedThreadPool for I/O instead.

---

## ReadWriteLock

```ruby
lock = Concurrent::ReadWriteLock.new

# Concurrent readers
10.times.map { Thread.new { lock.with_read_lock { read_data } } }.each(&:join)

# Exclusive writer
lock.with_write_lock { write_data }
```

Writers wait for all readers to finish; readers block during writes.

---

## IVar (Immutable Variable / Promise-like)

A one-time write, many-read container:

```ruby
ivar = Concurrent::IVar.new

producer = Thread.new { ivar.set(compute_result) }
consumer = Thread.new { puts ivar.value }  # blocks until set

ivar.complete?   # true after set or fail
ivar.failed?     # true if ivar.fail(reason) was called
```

---

## Event (one-time signal)

```ruby
event = Concurrent::Event.new

waiter = Thread.new { event.wait; puts "Go!" }
event.set   # unblocks all waiters
event.set?  # => true (can't be reset)
```

---

## Choosing the Right Abstraction

| Need | Use |
|------|-----|
| Run async, get value later | `Promises.future` |
| Chain async steps | `Promises.future.then.then` |
| Run N things in parallel | `Promises.zip(f1, f2, ...)` |
| Limit concurrency to N threads | `FixedThreadPool` |
| Concurrent key-value store | `Concurrent::Map` |
| Atomic integer counter | `AtomicFixnum` |
| Atomic flag | `AtomicBoolean` |
| Complex shared state | `Atom` |
| Limit resource access | `Semaphore` |
| Many readers, rare writes | `ReadWriteLock` |
| One-time value (write once) | `IVar` |
| One-time broadcast signal | `Event` |
| Recurring background task | `TimerTask` |
