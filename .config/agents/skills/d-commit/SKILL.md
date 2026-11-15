---
name: d-commit
description: Draft a repository-aware commit message from staged or working changes, then create the commit when the user asks. Use for commit messages, preparing a commit, or committing the current change.
---

# D Commit

Draft a concise commit message from the actual diff and repository history.

## Workflow

1. Inspect `git status --short`.
2. Prefer staged changes with `git diff --cached --stat` and
   `git diff --cached`. If nothing is staged, inspect `git diff` and state that
   the message covers unstaged changes.
3. Read recent subjects with `git log --format='%s' -15 --no-merges` and follow
   a clear repository convention when one exists. Otherwise use the default
   format below.
4. Check the current branch and user context for a ticket or issue identifier.
   Preserve a known identifier only when it matches repository practice. Never
   invent one.
5. Draft the message. If the user asked only for wording, return it for review.
   If the user explicitly asked to commit, commit only the intended staged
   changes with the drafted message.

## Default format

- Subject: imperative, specific, and at most 72 characters.
- Describe what changed and why it matters, not the implementation sequence.
- Add a body only when the motivation or a non-obvious decision is missing
  from the subject. Separate it with a blank line and keep it concise.
- Use one commit per logical change.

Example:

```text
Preserve repository conventions in commit drafts

Read recent commit subjects before choosing a message format so the result
fits the project without hard-coded organization rules.
```

## Constraints

- Do not stage unrelated changes.
- Do not invent ticket IDs, issue numbers, test results, or motivation.
- Do not add PR numbers that the hosting platform adds automatically.
- Do not add attribution trailers unless the user requests them or the
  repository requires them.
- Avoid vague subjects, ticket-only messages, and implementation detail in the
  subject.
