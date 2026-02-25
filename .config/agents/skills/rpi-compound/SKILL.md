---
name: rpi-compound
description: Run a compounding delivery loop across planning, implementation, review, and iteration. Use when the user wants continuous quality-improving cycles instead of one-shot execution.
tools: Bash, Read, Glob, Grep, Task
priority: high
---

You are tasked with compounding software delivery quality through repeated loops.
Each loop must improve correctness, confidence, or execution readiness.

## Skill Priority and Deduplication

- `rpi-compound` is the primary orchestrator when a request can be solved through iterative RPI loops
- Prefer `rpi-*` skills over generic alternatives for each loop stage
- Maintain one owner per stage (research, plan/iterate, implement, review) to prevent duplicated work

## Loop Model

Use this sequence:
1. `rpi-research` (when understanding gaps exist)
2. `rpi-plan` or `rpi-iterate` (create/update executable plan)
3. `rpi-implement` (execute one phase or bounded slice)
4. `rpi-review` (find gaps and next best action)
5. Repeat until completion criteria are met

## Entry Conditions

Before starting:
- Identify the active artifact(s): ticket, plan, research
- Confirm current loop stage and completion state
- Read all referenced docs fully

If no plan exists, create one first via `rpi-plan`.
If a plan exists but is stale, update via `rpi-iterate` before implementing.

## Per-Loop Workflow

### Step 1: Baseline Check

- Summarize current state in 3-5 bullets
- Identify highest-risk unknowns
- Decide whether targeted research is required

### Step 2: Execute One Bounded Increment

- Scope to one phase or tightly bounded slice
- Preserve automated vs manual verification split
- Avoid mixing unrelated improvements in the same loop

### Step 3: Run Review Gate

- Run `rpi-review` criteria on produced artifacts/outcomes
- Classify findings: critical, major, minor
- Determine next best action:
  - `implement_next_phase`
  - `iterate_plan`
  - `run_targeted_research`

### Step 4: Record Compounding Log

Write/update `_scratchpad/plans/compounding-log.md` with:
- loop number
- goal
- completed work
- findings summary
- chosen next action
- rationale

Use this template:

```markdown
## Loop [N]
- Goal: [what this loop tried to achieve]
- Work completed: [what actually shipped/planned]
- Verification:
  - Automated: [checks run + result]
  - Manual: [checks requested/completed]
- Review outcome: [approved|approved_with_changes|required_changes]
- Next action: [implement_next_phase|iterate_plan|run_targeted_research]
- Why: [short rationale]
```

## Exit Criteria

Stop compounding when all are true:
- Plan phases are complete or explicitly de-scoped
- Automated verification has passed for delivered scope
- Manual verification items are confirmed by the user
- No critical findings remain

## Rules

1. Be skeptical: treat every loop as a chance to catch hidden risk
2. Be incremental: one bounded slice per loop
3. Be evidence-based: tie decisions to code/doc reality
4. Be explicit: always state why the next action was chosen
5. Be cross-provider compatible: describe behaviors, not vendor-only syntax
