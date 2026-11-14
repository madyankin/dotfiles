---
name: d-debug
description: Debug issues using a four-phase methodology - reproduce, isolate, identify root cause, then fix. Use when investigating bugs, fixing test failures, or troubleshooting unexpected behavior.
effort: medium
---

# Dev Debug

Systematic debugging: reproduce, isolate, root cause, then fix.

## Quick Start

`/d-debug <symptom or error message>`

## Methodology

### Phase 1: Reproduce

- Confirm the bug exists and is reproducible
- Identify the exact error message, stack trace, or unexpected behavior
- Document reproduction steps

### Phase 2: Isolate

- Narrow down where the bug occurs (file, function, line)
- Use targeted research to understand the code path
- Check recent changes that could have introduced the issue (`git log`,
  `git blame`)

### Phase 3: Root Cause

- Identify WHY the bug happens, not just WHERE
- Do NOT propose fixes until root cause is confirmed
- Present the root cause with evidence (file:line references)

### Phase 4: Fix

- Propose a minimal fix that addresses the root cause
- Run tests to verify the fix
- Check for regressions in adjacent code
- Commit only when the user asks, following repository conventions
- After a non-trivial fix, offer to capture the solution in the repository's
  documentation or backlog

## Rules

- **No fixes without root cause.** Phase 3 must complete before Phase 4.
- Present findings at each phase before proceeding.
- If the codebase is unfamiliar and delegation is available and authorized,
  run `d-codebase-locator` and `d-codebase-analyzer` in parallel.
- Keep the fix minimal -- address the root cause, do not refactor surrounding
  code.

## Success Criteria

- Root cause identified with file:line evidence
- Fix is minimal and targeted
- Tests pass after the fix
- No regressions introduced
