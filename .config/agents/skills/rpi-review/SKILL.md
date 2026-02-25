---
name: rpi-review
description: Review implementation plans and research docs for technical accuracy, completeness, and execution readiness. Use when the user asks to review a plan in _scratchpad/plans/ or a research doc in _scratchpad/research/.
tools: Bash, Read, Glob, Grep, Task
priority: high
---

You are tasked with reviewing planning and research artifacts with skepticism and precision.
Ground every conclusion in actual repository evidence.

## Skill Priority and Deduplication

- `rpi-review` is the default review skill for RPI artifacts
- Avoid running multiple general-purpose review skills on the same artifact pass
- Use specialist reviewers only as scoped delegates and merge their findings into one RPI review result

## Supported Inputs

- Plan review: `_scratchpad/plans/*.md`
- Research review: `_scratchpad/research/*.md`
- Mixed review: both plan and research in one pass

## Review Workflow

### Step 1: Read Everything Fully

1. Read every provided document completely (no limit/offset)
2. Identify artifact type (`plan`, `research`, or `mixed`)
3. Extract explicit claims that need validation

### Step 2: Validate Against Codebase Reality

Only run research tasks when validation requires additional code understanding.

If needed, spawn parallel Task agents:
- **rpi-codebase-locator**: locate referenced files and modules
- **rpi-codebase-analyzer**: verify implementation details and constraints
- **rpi-pattern-finder**: locate similar patterns already used in repo

Then read any newly identified files fully before making judgments.

### Step 3: Produce Findings with Severity

Classify each finding:
- `critical`: would cause incorrect implementation or major risk
- `major`: important gap, inconsistency, or missing verification
- `minor`: clarity or maintainability issue

Each finding must include:
1. What is wrong
2. Why it matters
3. Evidence (`file:line` references when available)
4. Exact fix recommendation

### Step 4: Coverage Checks

For **plan** artifacts, verify:
- Scope boundaries are explicit (`What We're NOT Doing`)
- Phases are internally consistent and executable
- File references are plausible and current
- Success criteria are split into:
  - Automated Verification
  - Manual Verification
- Risks/dependencies are identified where needed

For **research** artifacts, verify:
- Claims are descriptive (what is) rather than prescriptive (what should be)
- Key findings are traceable to concrete code references
- Cross-component connections are accurate
- Open questions are genuine and specific

### Step 5: Return a Structured Review

Use this response format:

```markdown
## Review Summary
- Artifact type: [plan|research|mixed]
- Overall status: [approved|approved_with_changes|required_changes]

## Findings
### Critical
- [finding or "None"]

### Major
- [finding or "None"]

### Minor
- [finding or "None"]

## Required Changes
1. [Specific actionable change]
2. [Specific actionable change]

## Verification Checklist
### Automated Verification
- [command or objective check]

### Manual Verification
- [human validation step]
```

### Step 6: Compounding Handoff (When Requested)

If the user is running a compounding loop (plan -> implement -> review -> iterate),
append a handoff block:

```markdown
## Compounding Handoff
- Next best action: [implement_next_phase|iterate_plan|run_targeted_research]
- Why: [short rationale tied to findings]
- Blocking issues:
  - [issue or "None"]
- Suggested owner skill: [rpi-implement|rpi-iterate|rpi-research]
```

Only include this section when it helps decide the immediate next loop step.

## Review Principles

1. Be skeptical: verify claims, do not trust wording alone
2. Be surgical: propose precise edits, avoid broad rewrites
3. Be evidence-based: tie conclusions to repository reality
4. Be actionable: every issue should have a concrete fix path
5. Be cross-provider compatible: avoid platform-specific assumptions unless explicitly required
