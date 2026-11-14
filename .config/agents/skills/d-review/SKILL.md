---
name: d-review
description: Review implementation plans and research docs for technical accuracy, completeness, and execution readiness.
effort: medium
---

# Dev Review

Review planning and research artifacts with skepticism and precision. Ground
every conclusion in repository evidence.

## Quick Start

`/d-review _scratchpad/plans/<plan-file>.md`
`/d-review _scratchpad/research/<research-file>.md`

## Workflow

### Step 1: Read Everything

1. Read each provided document completely
2. Identify artifact type: plan, research, or mixed
3. Extract claims that need validation

### Step 2: Validate Against Codebase

Validate file references, implementation details, and claimed patterns against
the repository. When delegation is available and authorized, run
`d-codebase-locator`, `d-codebase-analyzer`, and `d-pattern-finder` in parallel.
Add only the focused reviewers relevant to the artifact:

- `d-architecture-strategist`: boundaries, coupling, architecture
- `d-simplicity-reviewer`: complexity and unnecessary abstraction
- `d-data-integrity-guardian`: invariants and consistency
- `d-data-migration-expert`: migrations and backfills
- `d-rails-reviewer`: Rails concerns
- `d-typescript-reviewer`: TypeScript concerns
- `d-schema-drift-detector`: schema evolution
- `d-agent-native-reviewer`: agent orchestration

### Step 3: Classify Findings

- **critical**: would cause incorrect implementation or major risk
- **major**: important gap, inconsistency, or missing verification
- **minor**: clarity or maintainability issue

Each finding must include: what is wrong, why it matters, evidence (file:line),
and exact fix recommendation.

### Step 4: Coverage Checks

For plans:

- Scope boundaries explicit
- Phases executable and consistent
- File references plausible and current
- Success criteria split into automated and manual
- Risks and dependencies identified

For research:

- Claims descriptive (what is) not prescriptive (what should be)
- Findings traceable to code references
- Cross-component connections accurate
- Open questions genuine and specific

### Step 5: Structured Review

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

## Compounding Handoff

- Next best action: [implement_next_phase|iterate_plan|run_targeted_research]
- Why: [rationale]
- Blocking issues: [issue or "None"]
- Suggested skill: [d-implement|d-iterate|d-research]
```

## Principles

1. Be skeptical: verify claims, do not trust wording alone
2. Be surgical: propose precise edits, avoid broad rewrites
3. Be evidence-based: tie conclusions to repository reality
4. Be actionable: every issue should have a concrete fix path

## Success Criteria

- Structured review produced with severity classification
- All claims validated against codebase reality
- Required changes are specific and actionable
- Compounding handoff section included when in a loop
