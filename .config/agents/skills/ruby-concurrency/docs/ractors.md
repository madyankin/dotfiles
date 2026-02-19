# Ruby Ractors

Ractors (Ruby Actor) provide true parallelism in MRI by giving each Ractor its own GVL. Introduced in Ruby 3.0, still marked **experimental** as of Ruby 3.3.

## Core Concept

Each Ractor is an isolated execution context:
- Has its own GVL → runs in true parallel with other Ractors
- Cannot directly access objects in other Ractors
- Communicates exclusively via message passing (send/receive or yield/take)

## Creating Ractors

```ruby
r = Ractor.new do
  # runs in parallel
  (1..10_000).reduce(:+)
end

result = r.take   # blocks until Ractor finishes, returns value
```

### Passing Arguments

```ruby
r = Ractor.new(42, "hello") do |num, str|
  "#{str}: #{num * 2}"
end
r.take  # => "hello: 84"
```

Arguments are moved or copied depending on shareability (see below).

---

## Communication: Send / Receive (Push Model)

The external caller pushes messages to the Ractor's incoming queue:

```ruby
worker = Ractor.new do
  loop do
    msg = Ractor.receive   # blocks until message arrives
    break if msg == :stop
    Ractor.yield msg * 2   # send result back
  end
end

worker.send(5)
worker.take   # => 10
worker.send(:stop)
```

### Receive with Select

```ruby
# Wait on multiple sources
r1 = Ractor.new { Ractor.yield "from r1" }
r2 = Ractor.new { Ractor.yield "from r2" }

ractor, value = Ractor.select(r1, r2)  # whichever is ready first
```

---

## Communication: Yield / Take (Pull Model)

The Ractor produces values; callers pull them:

```ruby
producer = Ractor.new do
  10.times { |i| Ractor.yield i }
end

10.times { puts producer.take }
```

---

## Shareable vs. Unshareable Objects

This is the central constraint of Ractors.

### Shareable Objects (can cross Ractor boundaries without copying)

- Numeric types (Integer, Float, Rational, Complex)
- Symbols
- `true`, `false`, `nil`
- Frozen strings (`"hello".freeze`, or string literals in Ruby 3 with `# frozen_string_literal: true`)
- Frozen arrays/hashes of shareable objects
- `Ractor` objects themselves
- Class and Module objects (but method calls still serialized inside a Ractor)

```ruby
Ractor.shareable?(42)           # => true
Ractor.shareable?("mutable")   # => false
Ractor.shareable?("frozen".freeze) # => true
```

### Making Objects Shareable

```ruby
data = { key: "value" }
Ractor.make_shareable(data)     # freezes deeply, modifies in place
Ractor.shareable?(data)         # => true
```

### Unshareable Object Handling

When you send an unshareable object:
- By default it is **moved** (the sending side loses access)
- Pass `move: false` to **copy** instead (marshal/unmarshal roundtrip)

```ruby
arr = [1, 2, 3]
r = Ractor.new { Ractor.receive }
r.send(arr)          # arr moved—arr is now invalid in the sender
# arr.first          # => Ractor::MovedError

r.send(arr, move: false)  # deep copy via Marshal
```

**Implication**: avoid sending large mutable objects repeatedly—they get marshalled on each send. Use shareable (frozen) data for read-heavy patterns.

---

## Patterns

### Parallel Map (Worker Pool)

```ruby
def parallel_map(items, workers: 4, &block)
  work = Ractor.make_shareable(block)
  queue = items.map { |i| [i, work] }

  pool = workers.times.map do
    Ractor.new do
      loop do
        item, fn = Ractor.receive
        Ractor.yield fn.call(item)
      end
    end
  end

  # Round-robin dispatch
  results = []
  queue.each_with_index do |(item, fn), i|
    pool[i % workers].send([item, fn])
  end

  items.size.times do
    _, value = Ractor.select(*pool)
    results << value
  end

  pool.each { |r| r.send(:stop) rescue nil }
  results
end

parallel_map([1, 2, 3, 4, 8], workers: 4) { |n| n ** n }
```

### Pipeline

```ruby
# Stage 1: generate numbers
stage1 = Ractor.new do
  (1..100).each { |i| Ractor.yield i }
end

# Stage 2: square them
stage2 = Ractor.new(stage1) do |src|
  loop { Ractor.yield src.take ** 2 }
end

# Stage 3: filter evens
stage3 = Ractor.new(stage2) do |src|
  loop do
    v = src.take
    Ractor.yield v if v.even?
  end
end

# Consume
results = []
loop do
  results << stage3.take
rescue Ractor::ClosedError
  break
end
```

### Supervisor Pattern

```ruby
supervisor = Ractor.new do
  workers = {}
  loop do
    msg = Ractor.receive
    case msg[:type]
    when :spawn
      id = msg[:id]
      workers[id] = Ractor.new(id) { |i| process(i) }
    when :result
      puts "Worker #{msg[:id]} done: #{msg[:value]}"
    when :stop
      break
    end
  end
end
```

---

## Limitations

### C Extensions

Most C extensions use global state and are **not Ractor-safe**. This blocks many popular gems from working inside Ractors:
- `openssl` — partially safe (some operations)
- `pg`, `mysql2` — not Ractor-safe
- `json` (default C extension) — not Ractor-safe (use `json` with pure Ruby backend)

Check with:
```ruby
Ractor.new { require 'some_gem' }
# If it raises Ractor::UnsafeError, the gem uses non-shareable constants
```

### No Shared Database Connections

Each Ractor needs its own connection. Don't share ActiveRecord connection pools across Ractors.

### Class-Level State

Constants and class variables are shared but must be frozen to be usable across Ractors:

```ruby
# OK: frozen constant
MULTIPLIER = 42

# Error: mutable class variable accessed from Ractor
class Foo
  @@state = []  # Ractor::IsolationError
end
```

### Debugging Is Harder

Stack traces don't cross Ractor boundaries. Wrap Ractor bodies in rescue blocks and log errors explicitly:

```ruby
Ractor.new do
  do_work
rescue => e
  # Log before Ractor dies silently
  warn "Ractor failed: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
  raise
end
```

---

## Performance Benchmarks (illustrative)

For CPU-bound tasks (e.g., computing large sums):

| Approach | 4 cores | Notes |
|----------|---------|-------|
| Sequential | 4x time | single core |
| Threads (MRI) | ~4x time | GVL prevents parallelism |
| Ractors | ~1.1–1.5x time | real parallelism, some overhead |
| `fork` | ~1.1x time | most overhead-free, but heavy process cost |

Ractors shine for pure Ruby CPU work. For I/O-bound work, threads or async fibers are more appropriate.

---

## When to Use Ractors

✅ CPU-bound computations in pure Ruby (image processing, parsing, cryptography)
✅ You can structure data as immutable/frozen
✅ You need parallelism without spawning processes
✅ Prototyping parallel algorithms

❌ When your gems are not Ractor-safe
❌ I/O-bound workloads (threads + async are better)
❌ When you need shared mutable state (use threads + Mutex)
❌ Production systems needing stability (still experimental)
