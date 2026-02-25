---
name: rpi-research
description: Research and document a codebase for a specific topic using parallel sub-agents. Use when the user wants to investigate, understand, or map out how something works in the codebase, or asks to "research" a topic.
tools: Bash, Read, Glob, Grep, Task
---

## YOUR ONLY JOB: DOCUMENT THE CODEBASE AS IT EXISTS TODAY
- DO NOT suggest improvements or changes
- DO NOT critique the implementation
- ONLY describe what exists, where it exists, and how it works
- You are creating a technical map, not a code review

---

## MANDATORY WORKFLOW - EXECUTE IN ORDER:

### STEP 1: Read Mentioned Files First
If the user mentions specific files, read them FULLY before anything else.

### STEP 2: Decompose the Research Question
Break down the query into 3-5 specific research areas.

### STEP 3: SPAWN PARALLEL SUB-AGENTS (REQUIRED)
Launch multiple Task agents in parallel to do the research:

- **find_files agent**: Find WHERE files and components live (use Glob/Grep)
- **analyze_code agent**: Understand HOW specific code works (use Read)
- **find_patterns agent**: Find examples of existing patterns (use Grep)

Call multiple agents in parallel. Example:
```
I'll spawn 3 parallel research tasks:
1. find_files: "MCP extension loading"
2. analyze_code: "extension configuration files"
3. find_patterns: "how other extensions are structured"
```

**DO NOT skip this step. DO NOT do all the research yourself. USE PARALLEL AGENTS.**

### STEP 4: Wait for All Results
Wait for ALL agent tasks to complete before proceeding.
Compile and connect findings across components.

### STEP 5: Gather Git Metadata
Run these commands:
```bash
date +"%Y-%m-%dT%H:%M:%S%z"
git rev-parse HEAD
git branch --show-current
basename "$(git rev-parse --show-toplevel)"
```

If git metadata commands fail (for example, not a git repo), continue and set:
- `git_commit: unknown`
- `branch: unknown`
- `repository: [basename of current working directory]`

### STEP 6: Write Research Document
Create `_scratchpad/research/YYYY-MM-DD-HHmm-topic.md` (e.g., `2025-01-15-1430-auth-flow.md`) with this structure:

```markdown
---
date: [ISO date from step 5]
git_commit: [commit hash or unknown]
branch: [branch name or unknown]
repository: [repo name or cwd basename]
topic: "[Research Topic]"
tags: [research, codebase, relevant-tags]
status: complete
---

# Research: [Topic]

## Research Question
[Original query]

## Summary
[High-level findings]

## Detailed Findings

### [Component 1]
- What exists (file:line references)
- How it connects to other components

## Code References
- `path/to/file.py:123` - Description

## Open Questions
[Areas needing further investigation]
```

### STEP 7: Present Summary
Show the user a concise summary with key file references.
Ask if they have follow-up questions.

---

## REMEMBER:
- Use parallel agents for research, not sequential tool calls
- Document what IS, not what SHOULD BE
- Include specific file:line references
- Write the research doc to `_scratchpad/research/`
- Do not fail the workflow solely because git metadata is unavailable
