---
name: d-research
description: Research and document a codebase for a specific topic using parallel sub-agents. Use when investigating, understanding, or mapping out how something works.
---

# Dev Research

Document the codebase as it exists today. No suggestions, no critique -- create
a technical map.

## Quick Start

`/d-research <topic or question>`

## Workflow

### Step 0: Detect Context

Determine whether you are in a **project** or a **workspace**:

```bash
git rev-parse --show-toplevel 2>/dev/null
```

- **Project mode** (command succeeds): CWD is inside a git repo. Write output to
  `_scratchpad/research/` within this repo.
- **Workspace mode** (command fails or CWD is above the git root): CWD contains
  multiple repos as subdirectories. Identify which repo(s) the research topic
  relates to and write output to each repo's `_scratchpad/research/`. If the research
  spans multiple repos, write a summary doc to the workspace's `_scratchpad/research/`
  and per-repo docs into each repo.

### Where files go

Write research docs to `_scratchpad/research/` at the root of the repo, or of the workspace in
workspace mode. `_scratchpad/` is local scratch. It ignores itself, so git never sees
it. Before the first write, run this in each root you write to:

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p "$root/_scratchpad/research"
[ -f "$root/_scratchpad/.gitignore" ] || printf '*\n' > "$root/_scratchpad/.gitignore"
```

Commit a file only when the user asks for that file by name. Then move it to
`docs/research/` and commit it from there. Never `git add -f` inside `_scratchpad/`.

### Step 1: Read Mentioned Files

If the user mentions specific files, read them fully before anything else.

### Step 2: Decompose the Research Question

Break down the query into 3-5 specific research areas.

### Step 3: Parallel Research

When delegation is available and authorized, run these agents in parallel:

- `d-codebase-locator`: locate relevant files and components
- `d-codebase-analyzer`: trace behavior, dependencies, and data flow
- `d-pattern-finder`: find established patterns and similar implementations

Give each a focused prompt. Otherwise perform the same decomposition directly.

Each agent gets a focused prompt describing what to find or analyze. Do not give
all research to a single agent.

### Step 4: Compile Results

Wait for all research to complete. Connect findings across components.

### Step 5: Gather Git Metadata

```bash
date +"%Y-%m-%dT%H:%M:%S%z"
git rev-parse HEAD
git branch --show-current
basename "$(git rev-parse --show-toplevel)"
```

If git metadata fails, set commit/branch to "unknown".

### Step 6: Write Research Document

Create `_scratchpad/research/YYYY-MM-DD-HHmm-topic.md` with this structure:

```markdown
---
date: [ISO date]
git_commit: [commit hash or unknown]
branch: [branch name or unknown]
repository: [repo name]
topic: "[Research Topic]"
tags: [research, codebase, relevant-tags]
status: complete
---

# Research: [Topic]

## Research Question

[Original query]

## Summary

[High-level findings in plain words: what exists, what is missing, what it
means for the question. No file:line refs here.]

## Detailed Findings

### [Component 1]

- What exists (file:line references)
- How it connects to other components

## Code References

- `path/to/file.py:123` - Description

## Open Questions

### [Question in one plain sentence]

- **Why it matters:** [what changes with the answer; two sentences at most]
- **Options:** [A, recommended because …] / [B]
- **Refs:** `path:line`
```

### Step 7: Present Summary

Show a concise summary and the open questions, written per "Writing for the
Reader". Link the doc for file references. Ask if there are follow-up
questions.

## Writing for the Reader

The user reads the summary and open questions without the code open.

- Define each term the user has not used yet, in plain words, at first use:
  a column, flag, metric, or internal name. Example: "`xpc` (conversions per
  euro of cost)".
- Say what a fact means for the question, not only where it is in code. Keep
  file:line refs in "Detailed Findings", "Code References" and `Refs:` lines.
- One open question asks one thing. If the user would have to ask "what is
  this?" before answering, rewrite it.

## Rules

- Document what IS, not what SHOULD BE
- Include specific file:line references
- In project mode: write the research doc to `_scratchpad/research/`
- In workspace mode: write per-repo research to each repo's `_scratchpad/research/`,
  and a cross-repo summary to the workspace's `_scratchpad/research/` if the topic
  spans repos

## Success Criteria

- Research document written to the correct `_scratchpad/research/` (per context
  detection)
- Research doc not staged or committed
- All decomposed areas covered
- File:line references included for key findings
- Summary and open questions follow "Writing for the Reader"
- Summary presented to the user

