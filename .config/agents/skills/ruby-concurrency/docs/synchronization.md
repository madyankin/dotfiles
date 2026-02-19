# Ruby Synchronization Primitives

## Mutex

A mutual exclusion lock. One thread at a time. Not re-entrant—the same thread calling `lock` twice deadlocks.

### API

```ruby
mutex = Mutex.new

mutex.synchronize { critical_section }   # preferred—safe, always unlocks

mutex.lock                               # blocks until acquired
mutex.unlock                             # must call from the locking thread
mutex.try_lock                           # non-blocking, returns true/false
mutex.locked?                            # inspection only (racy by nature)
mutex.owned?                             # true if current thread holds lock
mutex.sleep(timeout = nil)               # release lock, sleep, reacquire
```

### Pattern: Lazy initialization (double-checked locking)

```ruby
class Config
  def self.instance
    return @instance if @instance  # fast path without lock
    @mutex.synchronize do
      @instance ||= new            # safe path
    end
  end
end

# Simpler: use Concurrent::AtomicReference or Module-level constants
```

### Pattern: Timeout on lock acquisition

```ruby
acquired = mutex.try_lock
unless acquired
  # Back off, retry, or fail fast
  raise "Could not acquire lock"
end
begin
  critical_section
ensure
  mutex.unlock
end
```

### Deadlock Prevention

Rules:
1. Acquire multiple mutexes in a **consistent global order** across all threads
2. Keep critical sections **short**
3. Never call external code (callbacks, yield) while holding a lock
4. Prefer higher-level abstractions (`Queue`, `concurrent-ruby`) that manage locking internally

```ruby
# DEADLOCK: Thread A holds m1, waits for m2; Thread B holds m2, waits for m1
# FIX: Both threads acquire in the same order: m1 then m2
[m1, m2].sort_by(&:object_id).each(&:lock)
begin
  critical_section
ensure
  [m1, m2].each(&:unlock)
end
```

---

## ConditionVariable

Used to signal state changes between threads. Always paired with a Mutex.

### API

```ruby
cond = ConditionVariable.new

# Called inside mutex.synchronize
cond.wait(mutex)           # release lock, sleep until signal, reacquire lock
cond.wait(mutex, timeout)  # same but with timeout (seconds)
cond.signal                # wake one waiting thread
cond.broadcast             # wake all waiting threads
```

### Complete Producer-Consumer Example

```ruby
mutex   = Mutex.new
cond    = ConditionVariable.new
buffer  = []
LIMIT   = 5

producer = Thread.new do
  20.times do |i|
    mutex.synchronize do
      cond.wait(mutex) while buffer.size >= LIMIT  # backpressure
      buffer << i
      cond.signal
    end
  end
end

consumer = Thread.new do
  20.times do
    item = nil
    mutex.synchronize do
      cond.wait(mutex) while buffer.empty?  # WHILE, not if
      item = buffer.shift
      cond.signal
    end
    process(item)
  end
end

[producer, consumer].each(&:join)
```

**Always use `while`, not `if`**: after `cond.wait` returns, another thread may have already consumed the resource (spurious wakeup, or race).

### Timeout Pattern

```ruby
deadline = Time.now + 5  # 5-second timeout
mutex.synchronize do
  while queue.empty?
    remaining = deadline - Time.now
    break if remaining <= 0
    cond.wait(mutex, remaining)
  end
  raise "Timeout" if queue.empty?
  queue.shift
end
```

---

## Monitor

A re-entrant Mutex. The same thread can call `synchronize` recursively without deadlocking.

```ruby
require 'monitor'

# As a standalone object
mon = Monitor.new
mon.synchronize do
  mon.synchronize { }  # OK—same thread, re-entrant
end

# As a mixin
class SafeRegistry
  include MonitorMixin

  def initialize
    super  # REQUIRED to initialize MonitorMixin
    @data = {}
  end

  def register(key, value)
    synchronize { @data[key] = value }
  end

  def fetch_or_create(key)
    synchronize do
      @data[key] ||= synchronize { expensive_create(key) }
    end
  end

  def new_cond
    # Monitor provides its own ConditionVariable
    super
  end
end
```

### Monitor::ConditionVariable

```ruby
mon = Monitor.new
cond = mon.new_cond  # Monitor's own CV, not Thread::ConditionVariable

mon.synchronize do
  cond.wait_while { queue.empty? }  # cleaner than while loop
  cond.wait_until { !queue.empty? } # equivalent
end
```

**Use Monitor when**: you have recursive locking, or you want the `wait_while`/`wait_until` convenience API.

---

## SizedQueue (stdlib)

A thread-safe bounded FIFO queue. Blocks producer when full, blocks consumer when empty.

```ruby
require 'thread'

queue = SizedQueue.new(100)

# Blocks if full
queue.push(item)
queue << item

# Non-blocking (raises ThreadError if full)
queue.push(item, true)

# Pop (blocks if empty)
item = queue.pop

# Non-blocking (raises ThreadError if empty)
item = queue.pop(true)

queue.size    # current size
queue.empty?
queue.full?
```

### Sentinel Pattern (graceful shutdown)

```ruby
STOP = Object.new.freeze  # unique sentinel

workers = 4.times.map do
  Thread.new do
    loop do
      item = queue.pop
      break if item.equal?(STOP)
      process(item)
    end
  end
end

items.each { |i| queue << i }
workers.size.times { queue << STOP }  # one STOP per worker
workers.each(&:join)
```

---

## ReadWriteLock (concurrent-ruby)

Allows concurrent reads, exclusive writes.

```ruby
require 'concurrent-ruby'

lock = Concurrent::ReadWriteLock.new

# Multiple threads can read simultaneously
lock.with_read_lock { read_data }

# Only one thread can write (blocks all readers and writers)
lock.with_write_lock { mutate_data }
```

---

## Semaphore (concurrent-ruby)

Limits concurrency to N simultaneous threads:

```ruby
require 'concurrent-ruby'

sem = Concurrent::Semaphore.new(5)  # max 5 concurrent

threads = 100.times.map do
  Thread.new do
    sem.acquire
    begin
      limited_resource_call
    ensure
      sem.release
    end
  end
end
threads.each(&:join)
```

---

## AtomicReference / Atom (concurrent-ruby)

Lock-free atomic updates via CAS (compare-and-swap):

```ruby
require 'concurrent-ruby'

# AtomicReference: simple atomic set/get
ref = Concurrent::AtomicReference.new(0)
ref.get          # => 0
ref.set(1)
ref.get_and_set(2)         # returns old value (1), sets 2
ref.compare_and_set(2, 3)  # returns true, sets 3

# Atom: functional updates with retry on conflict
counter = Concurrent::Atom.new(0)
counter.swap { |v| v + 1 }    # atomic increment, retries on conflict
counter.reset(0)               # forceful set

# AtomicFixnum: optimized integer counter
n = Concurrent::AtomicFixnum.new(0)
n.increment   # atomic +=1
n.decrement   # atomic -=1
n.value       # current value
```

---

## Choosing the Right Primitive

| Scenario | Use |
|----------|-----|
| Protect a critical section | `Mutex#synchronize` |
| Re-entrant locking needed | `Monitor` |
| Signal between threads | `Mutex` + `ConditionVariable` |
| Bounded producer-consumer | `SizedQueue` |
| Limit concurrent access to N | `Concurrent::Semaphore` |
| Lock-free counter / flag | `Concurrent::AtomicFixnum` / `AtomicBoolean` |
| Lock-free complex state | `Concurrent::Atom` |
| Concurrent reads, rare writes | `Concurrent::ReadWriteLock` |
