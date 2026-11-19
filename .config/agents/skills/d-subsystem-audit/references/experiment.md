# Measured experiment recipe (Docker only)

Use when the value of a proposed change is in doubt: a rewrite in another
language, a library swap, a new algorithm, a config change (JIT, allocator,
pool size), a different storage layout.

1. **Real code, not a rewrite.** Copy the current implementation from the
   default branch (`git show origin/<default>:<file>`), stub only what app boot
   provides, and run it in the app's own image (e.g. `docker run --rm -m <limit>
   -v $SCRATCH:/b -w /app <app-image> ...`).
2. **Same input for every variant**, generated once with a fixed seed and
   realistic shape (size, churn, duplicates, garbage). Keep data in the
   session scratchpad, never in a repo.
3. **Assert identical outputs** across variants before quoting any timing.
4. **Measure per phase**: wall time, peak RSS (`/proc/self/status` VmHWM or
   `/usr/bin/time -f %M` — install `time` in slim images), and side effects on
   the host process: for interpreters with a global lock, run a probe thread
   that sleeps 10 ms in a loop and records lateness (n, p50, p99, max).
5. **Include cheap baselines**: current code with runtime flags (JIT,
   allocator), standard Unix tools, and only then new-language variants.
   Prefer std-only code (no network for dependencies).
6. **Project onto a real prod case**: calibration factor = prod phase time ÷
   (bench time × size ratio); apply it to the new variants; show scenarios
   with and without the upstream fixes the change depends on. State hardware
   differences (laptop arm64 vs prod x86_64).
7. **Packaging verdict**: compare subprocess, in-process FFI, native
   extension and separate service on crash isolation, memory return, lock
   behaviour, build/CI cost and runtime-upgrade risk — speed is usually equal.
