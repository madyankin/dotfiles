---
name: ruby-concurrency
description: Ruby concurrency expert - advises on threads, fibers, Ractors, GVL/GIL, async I/O, synchronization primitives, and the concurrent-ruby gem. Use when the user asks about Ruby threading, parallelism, race conditions, deadlocks, fiber schedulers, Ractor design, or scaling concurrent Ruby applications.
---

# Ruby Concurrency Expert

Expert guidance on Ruby concurrency, parallelism, and thread safety. Covers the full spectrum: GVL mechanics, threads, fibers, Ractors, async I/O, synchronization, and the concurrent-ruby gem.

## Concurrency Model at a Glance

| Primitive | Parallelism | Overhead | Scheduler | Best For |
|-----------|-------------|----------|-----------|----------|
| **Process** (`fork`) | ✅ True | High (own heap) | OS | CPU-bound, isolation |
| **Thread** | ⚠️ I/O only (MRI) | Medium | OS (preemptive) | I/O-bound, Rails |
| **Fiber** | ❌ | Very low | You (cooperative) | Generators, async I/O |
| **Ractor** | ✅ True | Medium | OS per-Ractor | CPU-bound, experimental |

## The GVL (Global VM Lock)

The GVL is a mutex that serializes Ruby bytecode execution across all threads within one MRI process. Only one thread runs Ruby code at a time.

**What it is NOT**: a bug, a performance flaw per se, or a guarantee of thread safety.

**When threads run in parallel** (GVL released): blocking I/O, `sleep`, `select`, native C extensions that release it explicitly (OpenSSL, MySQL2, pg, etc.).

**When threads are serialized**: pure Ruby computation, `Array#sort`, string manipulation—anything that stays in the Ruby VM.

```ruby
# Threads DO parallelize I/O (GVL released during blocking calls)
threads = 5.times.map do
  Thread.new { Net::HTTP.get(URI('https://api.example.com/data')) }
end
results = threads.map(&:value)  # ~1x latency instead of 5x

# Threads do NOT parallelize CPU work (GVL held)
threads = 5.times.map do
  Thread.new { 10_000_000.times.sum }  # No faster than sequential
end
```

**GVL does NOT guarantee thread safety.** Non-atomic Ruby operations (e.g., `n += 1`, `hash[k] ||= []`) can interleave across GVL handoffs.

### M:N Scheduling (Ruby 3.3+)

Ruby 3.3 introduced M:N thread scheduling (opt-in):
- M Ruby threads mapped to N OS threads (pool), reducing OS thread creation cost
- Especially beneficial for Ractor-heavy workloads
- Enable with `RUBY_MN_THREADS=1`, tune with `RUBY_MAX_CPU=n` (default: 8)

## Threads

### Lifecycle

```ruby
# Create
t = Thread.new { do_work }

# Pass values via block args (safer than closures for large data)
t = Thread.new(payload) { |data| process(data) }

# Join (wait, re-raises exceptions)
t.join

# Value (joins and returns block return value)
result = t.value

# Status: "run", "sleep", "aborting", false (finished), nil (exception)
t.status

# Kill (avoid—leaves resources unreleased)
t.kill
```

### Thread-Local Storage

```ruby
Thread.current[:request_id] = SecureRandom.uuid  # per-thread, not fiber-local
Thread.current.thread_variable_set(:name, "worker")  # also per-thread

# Fiber-local (prefer for code using Fibers):
# Plain Thread.current[:key] is actually fiber-local in Ruby 2.0+
```

### Exception Handling

By default, thread exceptions are swallowed silently:

```ruby
# ALWAYS set this or rescue in every thread
Thread.abort_on_exception = true  # global
t = Thread.new { raise "boom" }
t.abort_on_exception = true       # per-thread

# Or handle explicitly
t = Thread.new do
  do_work
rescue => e
  logger.error("Thread failed: #{e.message}")
end
```

## Synchronization Primitives

See [synchronization reference](docs/synchronization.md) for complete API.

### Mutex

Protects shared mutable state. Use `synchronize` (not raw `lock`/`unlock`):

```ruby
mutex = Mutex.new
counter = 0

threads = 10.times.map do
  Thread.new { 1000.times { mutex.synchronize { counter += 1 } } }
end
threads.each(&:join)
# counter == 10_000, guaranteed
```

**Deadlock rule**: always acquire multiple mutexes in the same order across all threads.

### ConditionVariable

Signals state changes between threads. Always used with a Mutex. Use `while` (not `if`) to guard against spurious wakeups:

```ruby
mutex = Mutex.new
cond  = ConditionVariable.new
queue = []

producer = Thread.new do
  10.times do |i|
    mutex.synchronize do
      queue << i
      cond.signal
    end
  end
end

consumer = Thread.new do
  10.times do
    mutex.synchronize do
      cond.wait(mutex) while queue.empty?  # while, not if
      puts queue.shift
    end
  end
end

[producer, consumer].each(&:join)
```

### Monitor (re-entrant Mutex)

Use when the same thread must acquire the lock recursively:

```ruby
require 'monitor'

class SafeCache
  include MonitorMixin

  def initialize
    super  # MUST call super
    @data = {}
  end

  def fetch(key)
    synchronize { @data[key] ||= synchronize { compute(key) } }
    # Re-entrant: inner synchronize doesn't deadlock
  end
end
```

## Fibers

Fibers are lightweight, cooperatively scheduled coroutines. The programmer controls switching; the VM never preempts.

```ruby
# Basic fiber
fiber = Fiber.new do
  Fiber.yield 1
  Fiber.yield 2
  3
end

fiber.resume  # => 1
fiber.resume  # => 2
fiber.resume  # => 3
fiber.resume  # => FiberError: dead fiber called
```

### Fibers as Generators (lazy sequences)

```ruby
fib = Fiber.new do
  a, b = 0, 1
  loop do
    Fiber.yield a
    a, b = b, a + b
  end
end

10.times { print "#{fib.resume} " }
# 0 1 1 2 3 5 8 13 21 34
```

### Non-blocking Fibers (Ruby 3.0+)

The Fiber Scheduler interface enables async I/O without callbacks:

```ruby
# Fiber::Scheduler hooks into blocking operations transparently.
# Standard library IO, Net::HTTP, sleep etc. all yield to scheduler.

require 'async'  # gem 'async'

Async do
  task1 = Async { Net::HTTP.get(URI('https://api1.example.com')) }
  task2 = Async { Net::HTTP.get(URI('https://api2.example.com')) }
  # Runs concurrently in one thread, no GVL release needed for scheduling
  [task1.wait, task2.wait]
end
```

See [fibers reference](docs/fibers.md) for scheduler internals and patterns.

## Ractors (Ruby 3.0+, experimental)

Ractors achieve true parallelism by giving each Ractor its own GVL. Object isolation enforces thread safety structurally.

### Key Constraints

- Ractors **cannot share mutable objects** — only shareable objects cross boundaries
- Shareable: frozen objects, Integers, Symbols, `Ractor` itself, `Ractor.make_shareable`
- Communication via `send`/`receive` (push) or `yield`/`take` (pull)
- Most C extensions are NOT Ractor-safe

```ruby
# CPU-bound parallelism: each Ractor runs on its own OS thread
workers = 4.times.map do |i|
  Ractor.new(i) do |id|
    # Heavy computation—runs in true parallel
    (1..1_000_000).reduce(:+)
  end
end

results = workers.map(&:take)
```

### Pipeline Pattern

```ruby
pipe = Ractor.new do
  loop { Ractor.yield Ractor.receive * 2 }
end

source = Ractor.new(pipe) do |out|
  5.times { |i| out.send(i) }
end

5.times { puts pipe.take }
```

See [ractors reference](docs/ractors.md) for design patterns and limitations.

## concurrent-ruby Gem

The `concurrent-ruby` gem provides production-ready high-level abstractions:

```ruby
gem 'concurrent-ruby'
```

### Promises (async pipelines)

```ruby
require 'concurrent-ruby'

promise = Concurrent::Promises.future { fetch_data }
  .then { |data| process(data) }
  .then { |result| save(result) }

promise.value!  # blocks, raises on error
promise.value   # blocks, returns nil on error
```

### Thread Pools

```ruby
# Fixed pool — predictable resource use
pool = Concurrent::FixedThreadPool.new(10)
pool.post { do_work }

# Cached pool — grows on demand, shrinks when idle
pool = Concurrent::CachedThreadPool.new
pool.post { do_work }

pool.shutdown
pool.wait_for_termination(30)
```

### Thread-Safe Data Structures

```ruby
map   = Concurrent::Map.new          # better than Hash + Mutex for most cases
array = Concurrent::Array.new        # thread-safe Array
hash  = Concurrent::Hash.new         # thread-safe Hash
atom  = Concurrent::Atom.new(0)      # CAS-based atomic value

atom.swap { |v| v + 1 }             # atomic update
atom.compare_and_set(0, 1)          # optimistic CAS
```

See [concurrent-ruby reference](docs/concurrent_ruby.md) for Agents, Timers, Semaphore.

## Processes

Best for CPU-bound parallelism without Ractor constraints:

```ruby
# Simple fork
pid = fork do
  result = heavy_computation
  exit!(result)  # exit! skips at_exit handlers and finalizers
end

Process.wait(pid)
status = $?.exitstatus

# With pipes for IPC
reader, writer = IO.pipe
pid = fork do
  reader.close
  writer.puts heavy_computation.to_json
  writer.close
end
writer.close
result = JSON.parse(reader.read)
reader.close
Process.wait(pid)
```

**Warning**: `fork` duplicates the entire process—don't fork with active DB connections, open files, or threads running. Call `fork` before connecting to external services.

## Common Patterns

### Worker Pool

```ruby
require 'concurrent-ruby'

class WorkerPool
  def initialize(size: 10)
    @pool = Concurrent::FixedThreadPool.new(size)
    @futures = Concurrent::Array.new
  end

  def submit(item)
    future = Concurrent::Promises.future_on(@pool) { yield item }
    @futures << future
    future
  end

  def results
    Concurrent::Promises.zip(*@futures).value!
  end

  def shutdown = @pool.shutdown && @pool.wait_for_termination
end
```

### Producer-Consumer Queue

```ruby
require 'thread'  # SizedQueue is in stdlib

queue = SizedQueue.new(100)  # blocks producer when full

producer = Thread.new do
  items.each { |item| queue << item }
  queue << :done
end

consumer = Thread.new do
  loop do
    item = queue.pop
    break if item == :done
    process(item)
  end
end

[producer, consumer].each(&:join)
```

### Parallel HTTP Requests

```ruby
# With threads (simple, works on MRI—GVL released during I/O)
require 'net/http'

urls = %w[https://api1.com https://api2.com https://api3.com]
threads = urls.map do |url|
  Thread.new { Net::HTTP.get(URI(url)) }
end
responses = threads.map(&:value)

# With async gem (single thread, fiber-based, more efficient)
require 'async'
require 'async/http/internet'

responses = Async do |task|
  internet = Async::HTTP::Internet.new
  tasks = urls.map { |url| task.async { internet.get(url).read } }
  tasks.map(&:wait)
end
```

## Diagnosing Issues

### Detecting Race Conditions

```ruby
# thread_safe gem or manual: run code with many threads repeatedly
100.times.map { Thread.new { shared_operation } }.each(&:join)
# If result is non-deterministic, you have a race condition
```

### Deadlock Symptoms

- All threads blocked on `join` or `mutex.lock`
- Ruby prints "deadlock detected" and exits
- Fix: consistent lock ordering, use `Mutex#try_lock` with backoff, or use `Monitor`

### Thread Dump

```ruby
# Print backtraces for all threads (useful in rescue blocks or signal handlers)
Signal.trap('USR1') do
  Thread.list.each do |t|
    STDERR.puts "--- Thread #{t.object_id} (#{t.status}) ---"
    STDERR.puts t.backtrace.join("\n")
  end
end
# kill -USR1 <pid>
```

### GVL Profiling

```ruby
# gvl-tracing gem shows per-thread GVL acquisition
# gem 'gvl-tracing'
require 'gvl-tracing'
GvlTracing.start('trace.json') { your_concurrent_code }
# Open trace.json in chrome://tracing
```

## Decision Guide

**I/O-bound work (HTTP, DB, files)**: Use **threads** or the **async gem** (fibers). Threads are simpler; async is more efficient at high concurrency.

**CPU-bound work, need parallelism**: Use **Ractors** (if object isolation feasible), **processes** (safest, highest overhead), or switch to JRuby/TruffleRuby.

**Cooperative sequencing / generators**: Use **Fibers**.

**High-level abstractions**: Use **concurrent-ruby** (`Promises`, `FixedThreadPool`, `Atom`).

**Shared mutable state**: Wrap with `Mutex`, use `Monitor` if re-entrant, or eliminate sharing (prefer message-passing or immutable data).

## Reference Docs

- [Synchronization Primitives](docs/synchronization.md) — Mutex, ConditionVariable, Monitor, Semaphore
- [Fibers & Fiber Scheduler](docs/fibers.md) — Cooperative concurrency, async gem, scheduler interface
- [Ractors](docs/ractors.md) — Shareable objects, messaging, design patterns, limitations
- [concurrent-ruby](docs/concurrent_ruby.md) — Promises, thread pools, atomic types, actors
