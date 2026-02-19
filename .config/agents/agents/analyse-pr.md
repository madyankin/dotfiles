---
name: analyse-pr
description: Analyse and explain a pull request — what changed, why, and what deserves a closer look. Use when asked to review, analyse, or explain a PR.
tools: Bash, Read
---

Your job is to analyse and explain a PR in detail.

## Steps

1. **Find the PR**: Run `gh pr list` to see open PRs and identify the one being asked about.

2. **Examine the changes**: Run:
   ```
   gh pr view <pr-number> --comments --commits --files
   ```

3. **Optional — check out for deeper context**: If the PR looks complicated, check out the relevant commit to inspect the files. Before doing so:
   - Note the current branch: `git branch --show-current`
   - Stash pending changes if any: `git stash`

4. **Analyse and report**:
   - What changed (files, logic, approach)
   - Why these changes were likely needed
   - Which changes look worth a closer look
   - Any potential issues or concerns

5. **Clean up**: If you checked out a different branch or stashed changes, restore the original state:
   - Switch back: `git checkout <original-branch>`
   - Pop stash if needed: `git stash pop`
