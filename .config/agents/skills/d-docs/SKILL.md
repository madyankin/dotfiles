---
name: d-docs
description: Audit and update documentation after code changes. Checks repo-level docs, code comments, API specs, and stories for drift. Use after implementing changes or as part of code review.
effort: medium
---

# Dev Docs

Keep documentation in sync with code. Two modes: **fix** (default) updates docs
in place, **review** reports findings without changing files.

## Quick Start

Fix mode (update docs): `/d-docs`
Review mode (report only): `/d-docs review`

## Modes

- **Fix** (default): read the diff, find stale docs, update them. Used during or
  after implementation.
- **Review**: read the diff, find stale docs, report findings in the structured
  review format. Used by `d-code-review` before PRs.

## Workflow

### 1. Detect What Changed

```bash
git diff main...HEAD --name-only
```

Categorize changed files:

- **Ruby** (controllers, models, services, workers, serializers)
- **TypeScript/React** (components, hooks, utilities, stories)
- **Go** (packages, exported types, handlers)
- **Config/infra** (Dockerfile, docker-compose, Makefile, CI)
- **Docs themselves** (docs/\*.md, AGENTS.md, README.md)

### 2. Discover Repo Documentation

Read the repo's `AGENTS.md` to understand:

- Which docs exist and what each covers (the "Canonical Docs" or equivalent
  section)
- What documentation conventions are expected (quality checklists, comment
  rules)
- What code comment style is used (look at existing files for patterns)

Then list the `docs/` directory to see all available documentation files.

This makes the skill repo-agnostic — it works in any repo by reading that repo's
own instructions rather than hardcoding file paths.

### 3. Match Changes to Docs

For each changed file from step 1, determine which docs could be affected:

1. Read the doc file descriptions from `AGENTS.md` (e.g., "`docs/security.md` -
   authentication/authorization, input handling")
2. Match the changed code area to the doc that covers it (e.g., changed a
   controller auth check → `docs/security.md`)
3. Also always check `AGENTS.md` and `README.md` if the changes affect build
   commands, skills, or repo structure

Read each matched doc and compare with the current code. Check for:

- Outdated descriptions of behavior that has changed
- References to files, classes, or functions that have been renamed or removed
- Missing coverage of newly added features or endpoints
- Stale examples or code snippets

### 4. Check Code Comments

Read the repo's documentation conventions (from `AGENTS.md` and `docs/`) to
understand what comment style is expected. Then check changed files against
those conventions.

Common patterns to look for (adapt to what the repo actually uses):

- **Top-level class/module/component comments**: most repos require these. Check
  they exist and describe the current purpose.
- **Doc tags on public interfaces** (`@param`, `@return`, `@raises`, JSDoc,
  GoDoc, YARD): if the file already uses them, check they match current
  signatures. Do not add doc tags to files that don't already use them.
- **Section labels or structural comments**: if the repo convention requires
  them (e.g., section markers in React components), check they're present.
- **Deprecation markers**: if a function/component is being replaced, check for
  `@deprecated` markers.

### 5. Check Derived Artifacts

Look for generated or co-located artifacts that may need updating:

- **API specs** (OpenAPI, Swagger): if endpoint behavior changed, flag that
  specs may need regeneration
- **Storybook stories**: if a component's props or behavior changed, check
  whether co-located stories cover the new behavior
- **READMEs in subdirectories**: if a shared utility or library changed, check
  its local README

For derived artifacts, prefer flagging for manual review over auto-fixing — they
often need human verification.

### 6. Produce Output

#### Fix Mode

For each issue found:

1. Update the doc or comment in place
2. Keep the existing style and tone — match the surrounding documentation
3. Make minimal, targeted edits — do not rewrite entire files
4. For repo-level docs: update only the sections affected by the code change
5. For code comments: update to reflect current behavior
6. For derived artifacts (OpenAPI, stories): flag for manual action if
   auto-update is not feasible

Present a summary of changes made:

```markdown
## Documentation Updates

### Updated

- `docs/security.md` — updated authentication section to reflect new flow
- `src/services/user_service.rb:15` — updated top-level comment to include new responsibilities

### Flagged for Manual Review

- API spec may need regeneration — new endpoint added
- `src/components/Form/Form.stories.tsx` — props changed, stories may need new variants
```

#### Review Mode

Produce findings in the standard review format:

```markdown
## Documentation Review

### Critical

- [Doc issues that would mislead developers or agents — e.g., AGENTS.md references a deleted file]

### Suggestion

- [Doc drift that should be fixed — e.g., security.md describes old auth flow]

### Nit

- [Minor — e.g., missing top-level comment on new service class]
```

## Integration Points

- **`d-code-review`**: invoke `d-docs review` as part of the review to check
  doc freshness
- **Standalone**: run `/d-docs` after any implementation work to catch doc
  drift

## Rules

1. Match the existing documentation style — do not impose a new style
2. Update existing docs; do not add doc comments to files/repos that don't
   already use them
3. Do not rewrite sections unrelated to the code change
4. For ambiguous cases (is this doc still accurate?), flag for manual review
   rather than guessing
5. Treat OpenAPI specs and Storybook stories as "flag, don't auto-fix" — these
   often need manual verification

## Success Criteria

- All changed files checked for doc comment freshness
- Relevant repo-level docs checked against the diff
- Fix mode: stale docs updated, summary presented
- Review mode: findings reported in structured format
- No false positives from docs unrelated to the change
