---
name: d-plan
description: Create detailed implementation plans through an interactive process. Use when planning a feature, ticket, or technical change before implementing.
---

# Dev Plan

Create detailed, phased implementation plans through research and collaboration.

## Quick Start

`/d-plan <ticket-id or description>`

## Process

### Step 0: Detect Context

Determine whether you are in a **project** or a **workspace**:

```bash
git rev-parse --show-toplevel 2>/dev/null
```

- **Project mode** (command succeeds): CWD is inside a git repo. Write the plan
  to `_scratchpad/plans/` within this repo.
- **Workspace mode** (command fails or CWD is above the git root): CWD contains
  multiple repos. If the task spans multiple repos:
  1. Write an **umbrella plan** to the workspace's `_scratchpad/plans/`. This plan
     describes the overall goal and references per-repo sub-plans.
  2. Write **sub-plans** to each affected repo's `_scratchpad/plans/`. Each sub-plan is
     self-contained and can be executed independently with `/d-implement`.
  3. The umbrella plan's phases should map to the sub-plans, e.g., "Phase 1: API
     changes (see `api/_scratchpad/plans/...`)", "Phase 2: Frontend changes (see
     `frontend/_scratchpad/plans/...`)".

### Where files go

Write plans to `_scratchpad/plans/` at the root of the repo, or of the workspace in
workspace mode. `_scratchpad/` is local scratch. It ignores itself, so git never sees
it. Before the first write, run this in each root you write to:

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p "$root/_scratchpad/plans"
[ -f "$root/_scratchpad/.gitignore" ] || printf '*\n' > "$root/_scratchpad/.gitignore"
```

Commit a file only when the user asks for that file by name. Then move it to
`docs/plans/` and commit it from there. Never `git add -f` inside `_scratchpad/`.

### Step 1: Context Gathering

1. Read all mentioned files fully (tickets, research docs, related plans)
2. When delegation is available and authorized, run `d-codebase-locator`,
   `d-codebase-analyzer`, and `d-pattern-finder` in parallel. Otherwise perform
   those passes directly.
3. Read all files identified by research
4. Present understanding. Then rate each area Clear, Partial or Missing:
   scope and behavior; data and states; edge cases and failures; limits
   (performance, security, privacy); other services and integrations; how we
   know it is done. Ask only about Partial or Missing areas that code cannot
   answer. Ask at most 5 questions, one at a time. Each question gives 2-3
   options and marks one as recommended; "yes" accepts it.

### Step 2: Research and Discovery

1. If the user corrects a misunderstanding, verify with new research
2. External research gate: always research when the plan touches security/auth,
   billing/payments, data migrations, privacy/compliance, or public API
   contracts
3. Turn each unknown into one research task, and run the tasks in parallel.
   The unknowns are: each Partial or Missing area from Step 1, each new
   dependency, and each call into another service. External findings carry a
   link and the date read. A claim with no source is marked as an assumption.
4. Present findings and 2-3 design options with pros/cons. Record each choice
   under `## Decisions`.
5. An unknown you cannot resolve stays under Open Questions. Every phase that
   depends on it gets a `**Blocked by**: [question]` line.

### Step 3: Plan Structure

Create an outline and get feedback before writing details.

Every new unit in the outline names its need in one line. A unit is a class,
module, table, column, worker, job, endpoint, config key, or phase. A need is a
ticket AC, a user request, or a case that fails today. Then take one branch and
say which in the outline:

- **Need named:** keep it.
- **No need, but it would help:** move it to "Optional, not in plan" with one
  line on what it buys. The user opts in.
- **No need:** drop it.

Before you add a unit, check whether an existing one can carry the change. A
shared or core model must not learn about one feature's internals; keep that
knowledge in the feature's own namespace.

Place logic next to the data it uses, and say where in the outline. Before you
add a class, module or type, name the work it does that the data's owner or the
caller cannot. If you cannot, put the logic there.

Each repo can hold its own placement rules in a lens. In each repo the plan
touches, look for `.agents/skills/d-implement-<repo>/SKILL.md`, where
`<repo>` is `basename -s .git "$(git remote get-url origin)"`; if it is
missing, also try `.agents/skills/d-implement-lens/SKILL.md`. Say
`Lens: <path>` or `Lens: none` per repo. A found lens is read whole, with its
links; its rules add to these, and win on a conflict.

When a unit has to break a lens rule or the placement rule, add a row to
"Rule Exceptions". dev-implement treats a listed exception as approved, not as
a mismatch.

### Step 4: Write the Plan

Write to `_scratchpad/plans/YYYY-MM-DD-HHmm-description.md`:

```markdown
---
origin:
  ticket: [ticket-id]
  research:
    - [research-doc-path]
  related_plans:
    - [plan-path]
last_updated: [YYYY-MM-DD]
---

# [Feature/Task Name] Implementation Plan

## Overview

[What we are implementing and why]

## Current State Analysis

[What exists, what is missing, key constraints]

## Desired End State

[Specification and how to verify it]

## What We Are NOT Doing

[Out-of-scope items to prevent scope creep]

## Clarifications

### Session YYYY-MM-DD

- Q: [question] → A: [answer]

## Decisions

### [Choice in one plain sentence]

- **Decision:** [what we chose]
- **Why:** [the reason, with a ref or link]
- **Rejected:** [option] — [why not]

## Implementation Approach

[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview

[What this phase accomplishes]

### Changes Required

#### 1. [Component/File Group]

**File**: `path/to/file.ext`
**Need**: [AC, user request, or failing case this serves]
**Changes**: [Summary]

### Success Criteria

#### Automated Verification

- [ ] Tests pass
- [ ] Linting passes

#### Manual Verification

- [ ] Feature works as expected

## Testing Strategy

### Unit Tests

[What to test and edge cases]

### Integration Tests

[End-to-end scenarios]

## Open Questions

### [Question in one plain sentence]

- **Why it matters:** [what changes with the answer; two sentences at most]
- **Options:** [A, recommended because …] / [B]
- **Refs:** `path:line`

## Rule Exceptions

| Rule broken | Why needed | Simpler option rejected because |
| ----------- | ---------- | ------------------------------- |

## Optional, not in plan

- [Unit]: [what it would buy]
```

## Writing for the Reader

The user reads the outline, open questions and summary without the code open.

- Define each term the user has not used yet, in plain words, at first use:
  a column, flag, metric, or internal name. Example: "`insufficient` (a flag
  that says the metric had too little data)".
- Say what a fact means for the decision, not only where it is in code. Keep
  file:line refs in "Changes Required" and on `Refs:` lines, not in summary
  sentences.

## Common Patterns

- Database changes: schema/migration, store methods, business logic, API,
  clients
- New features: data model, backend logic, API endpoints, UI last
- Refactoring: document current behavior, incremental changes, maintain
  backwards compatibility

## Success Criteria

- Plan document written to the correct `_scratchpad/plans/` (per context detection)
- Plan not staged or committed
- In workspace mode: umbrella plan references per-repo sub-plans, each sub-plan
  is self-contained
- Frontmatter complete with origin references
- Every change item has a **Need** line; units without one are dropped or
  under "Optional, not in plan"
- Each phase has automated and manual success criteria
- Out-of-scope section explicitly defined
- Every answer the user gave sits under Clarifications, and the section it
  changes reflects it
- Every design choice sits under Decisions with its rejected options

