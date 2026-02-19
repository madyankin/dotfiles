# Ruby Fibers & Fiber Scheduler

## What Fibers Are

Fibers are lightweight coroutines—code blocks that can be suspended and resumed at programmer-defined points. They are:
- **Cooperatively scheduled**: never preempted; they yield voluntarily
- **Extremely cheap**: hundreds of thousands can coexist (~4KB initial stack vs ~1MB for threads)
- **Single-threaded**: fiber switching within a thread never involves the OS scheduler

## Core API

```ruby
# Create
f = Fiber.new { block }

# Resume (start or continue)
f.resume         # => value passed to Fiber.yield, or block's return value

# Yield (suspend, pass value out)
Fiber.yield(value)

# Transfer (resume another fiber directly)
f.transfer       # lower-level; fiber can't be resumed normally after transfer

# Alive?
f.alive?         # false after block returns
```

### Passing Values In and Out

```ruby
fiber = Fiber.new do |initial|
  second = Fiber.yield(initial * 2)   # yields, receives next resume's arg
  second * 10
end

fiber.resume(3)   # => 6   (3 * 2)
fiber.resume(7)   # => 70  (7 * 10, block ends)
fiber.resume      # => FiberError: dead fiber called
```

## Pattern: Generator / Infinite Sequence

Fibers excel at lazy sequences where computing the next element requires keeping state:

```ruby
def fibonacci
  Fiber.new do
    a, b = 0, 1
    loop do
      Fiber.yield a
      a, b = b, a + b
    end
  end
end

fib = fibonacci
20.times { print "#{fib.resume} " }
# 0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181

# Composable: wrap in Enumerator for full Enumerable support
fib_enum = Enumerator.new { |y| loop { y << fib.resume } }
fib_enum.take(10)  # => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

## Pattern: State Machine

```ruby
traffic_light = Fiber.new do
  loop do
    Fiber.yield :red
    Fiber.yield :green
    Fiber.yield :yellow
  end
end

5.times { puts traffic_light.resume }
# red, green, yellow, red, green
```

## Pattern: Resumable Parser / Tokenizer

```ruby
def tokenizer(input)
  Fiber.new do
    input.each_char.chunk_while { |a, b| a.match?(/\w/) == b.match?(/\w/) }
         .each { |chars| Fiber.yield chars.join }
  end
end

t = tokenizer("hello, world! 42")
loop { print "[#{t.resume}] "; break unless t.alive? }
# [hello][, ][world][! ][42]
```

---

## Fiber Scheduler (Ruby 3.0+)

Ruby 3.0 introduced `Fiber::SchedulerInterface`, allowing a scheduler to intercept blocking operations and switch to another fiber instead of blocking the OS thread.

### How It Works

When a non-blocking Fiber hits a blocking call (IO, sleep, DNS lookup), the runtime calls the scheduler's hook. The scheduler can then:
1. Register the I/O descriptor with an event loop (epoll/kqueue/select)
2. Resume another fiber that has work
3. When the I/O is ready, resume the original fiber

All of this happens within **one OS thread** with **no GVL overhead**.

### Setting a Scheduler

```ruby
class MyScheduler
  def io_wait(io, events, timeout)
    # Register io with event loop, return when ready
  end

  def kernel_sleep(duration = nil)
    # Schedule wakeup after duration
  end

  def process_wait(pid, flags)
    # ...
  end

  def block(blocker, timeout = nil)
    # Called for Mutex.lock, Thread.join, etc.
  end

  def unblock(blocker, fiber)
    # Wake up a blocked fiber
  end

  def close
    # Run event loop until all fibers done
  end
end

Fiber.set_scheduler(MyScheduler.new)

# Now non-blocking fibers in this thread use the scheduler
Fiber.new { Net::HTTP.get(URI("https://example.com")) }.resume
```

### async gem (production-ready scheduler)

The `async` gem provides a complete, battle-tested implementation:

```ruby
# Gemfile: gem 'async'
require 'async'
require 'net/http'

# Run concurrent tasks in one thread
Async do |task|
  tasks = urls.map do |url|
    task.async do
      Net::HTTP.get(URI(url))   # yields to scheduler automatically
    end
  end
  results = tasks.map(&:wait)
end

# Nested tasks
Async do |parent|
  child = parent.async { sleep 1; "done" }
  child.wait  # => "done"
end

# Timeouts
Async do |task|
  task.with_timeout(5) do
    slow_io_operation
  end
end
```

### async/http for concurrent HTTP

```ruby
require 'async'
require 'async/http/internet'

Async do
  internet = Async::HTTP::Internet.new

  responses = urls.map do |url|
    Async { internet.get(url) }
  end

  bodies = responses.map { |r| r.wait.read }
  internet.close
end
```

### Non-blocking Fiber vs Thread Comparison

| | Thread | Non-blocking Fiber |
|-|--------|-------------------|
| Parallelism | I/O (MRI) | No (single thread) |
| Context switch cost | OS (expensive) | Ruby VM (cheap) |
| Memory per unit | ~1MB | ~4KB |
| Preemption | Yes (GVL handoff) | No (explicit yield) |
| Error propagation | Tricky (silent) | Explicit (raise) |
| Suitable scale | Hundreds | Tens of thousands |

---

## Fiber Storage (Ruby 3.1+)

Thread-local storage is shared among fibers in the same thread. Fiber storage is truly fiber-local:

```ruby
# Thread-local (shared by all fibers in the thread):
Thread.current[:key] = "shared"

# Fiber-local (isolated per fiber):
Fiber[:key] = "isolated"
Fiber.current.storage[:key] = "also isolated"
```

This matters for context propagation (request IDs, spans, etc.) in async code where many fibers share one thread.

---

## Common Mistakes

### Mistake: Using `if` instead of `while` in scheduler loops

```ruby
# WRONG: another fiber may consume the item before this one wakes
if queue.empty?
  scheduler.wait_for_item
end

# RIGHT: re-check after wakeup
while queue.empty?
  scheduler.wait_for_item
end
```

### Mistake: Calling `resume` on a dead fiber

```ruby
f = Fiber.new { 1 }
f.resume  # => 1
f.resume  # => FiberError: dead fiber called
# Guard with f.alive?
```

### Mistake: Sharing fiber-unsafe state across scheduled fibers

In async code, control can switch at any `await` point. Treat the region between awaits as a critical section:

```ruby
# UNSAFE in async context
@counter += 1  # another fiber may run between read and write

# SAFE: use Mutex even in async code for mutable shared state
@mutex.synchronize { @counter += 1 }
# OR: use Concurrent::AtomicFixnum
```

### Mistake: Blocking inside a non-blocking fiber without scheduler

```ruby
Fiber.new {
  # This blocks the ENTIRE THREAD (no scheduler set)
  sleep 1
}.resume
```

Always set a scheduler before creating non-blocking fibers, or use a framework (async gem) that sets it for you.
