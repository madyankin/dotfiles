---
name: d-iterate
description: Update an existing implementation plan based on feedback. Use when modifying, refining, or extending a plan in _scratchpad/plans/.
---

# Dev Iterate

Update existing implementation plans based on user feedback.

## Quick Start

`/d-iterate _scratchpad/plans/<plan-file>.md`

Older plans may still sit in `docs/plans/`. Accept any path the user gives.
Never stage or commit the plan.

## Process

### Step 1: Read and Understand

1. Read the existing plan file completely
2. Parse what the user wants to add, modify, or remove

### Step 2: Research If Needed

Only spawn research tasks if the changes require new technical understanding.

If delegation is available and authorized, run `d-codebase-locator`,
`d-codebase-analyzer`, and `d-pattern-finder` in parallel. Otherwise perform
those passes directly.

### Step 3: Check Units, Then Confirm

A unit is a class, module, method, table, column, callback, worker, job,
endpoint, config key, or phase. Check every unit the edit adds, and every
existing plan unit the edit touches or the user asks about.

**Need.** A need is a ticket AC, a user request, or a case that fails today.
A request to split, merge or move code is the need for the change, not for
each new class; each class still needs its own. Take one branch per unit:

- **Need named:** keep it, with a `**Need**:` line in the plan.
- **No need, but it would help:** move it to "Optional, not in plan" with one
  line on what it buys. The user opts in.
- **No need:** drop it.

Code that already exists and does not change is not a unit. Do not list it
under "Changes Required".

**Placement.** Put logic next to the data it uses. Before you add a class, module or
type, name the work it does that the data's owner or the caller cannot. If
you cannot, put the logic there.

**Repo lens.** In each repo the plan touches, look for
`.agents/skills/d-implement-<repo>/SKILL.md`, where `<repo>` is
`basename -s .git "$(git remote get-url origin)"`; if it is missing, also try
`.agents/skills/d-implement-lens/SKILL.md`. Say `Lens: <path>` or
`Lens: none` per repo. A found lens is read whole, with its links; its
placement rules add to these, and win on a conflict.

Then confirm:

```text
Based on your feedback, I understand you want to:
- [Change 1]

My research found:
- [Relevant discovery]

Lens: [path | none]

Units:
- [Unit] in [place, per lens or the generic rule]: [keep — need | optional — what it buys | drop]

I plan to update the plan by:
1. [Specific modification]

Does this align with your intent?
```

Get user confirmation before proceeding.

### Step 4: Update the Plan

- Make focused, precise edits -- not wholesale rewrites
- Maintain existing structure unless explicitly changing it
- Keep file:line references accurate
- Every changed or added item carries a `**Need**:` line; optional units go
  under "Optional, not in plan"
- Update success criteria if needed
- If adding a phase, follow the existing pattern
- If modifying scope, update the "What We Are NOT Doing" section
- Log answers to questions asked in this run under `## Clarifications`, in
  `### Session YYYY-MM-DD`. Create the section if the plan has none. Never
  edit older entries: a reversed answer gets a new entry.
- If the plan is an umbrella plan with sub-plans in repo subdirectories,
  propagate relevant changes to the affected sub-plans too

### Step 5: Report Changes

```text
Updated the plan at _scratchpad/plans/[filename].md

Changes made:
- [Change 1]
- [Change 2]

Any further adjustments?
```

## Guidelines

1. Be skeptical: question vague feedback, verify feasibility
2. Be surgical: precise edits, preserve good content
3. No open questions: if the change raises questions, ask before updating

## Success Criteria

- Plan updated with focused, precise edits
- User confirmed the changes match their intent
- Every added or touched unit has a need and a placement, said in Step 3,
  with the lens case per repo
- Success criteria updated if scope changed
- Automated and manual verification distinction maintained

