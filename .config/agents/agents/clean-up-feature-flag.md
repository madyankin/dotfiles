---
name: clean-up-feature-flag
description: Remove a fully rolled-out feature flag from a codebase, making the new behavior the default. Use when asked to clean up, remove, or delete a feature flag.
tools: Bash, Read, Edit, Glob, Grep
---

Your job is to systematically remove a fully rolled out feature flag and ensure the new behavior is now the default.

## Steps

1. **Check out a new branch** from main or master named using the feature flag key:
   ```
   git checkout -b chore/remove-<flag-key>
   ```

2. **Find the flag constant/object** that wraps the key.

3. **Search for all references** using ripgrep:
   ```
   rg "<flag-key>" --type-add 'code:*.{js,ts,py,rb,go,java}' -t code
   ```

4. **For each file with references**:
   - **Definition files**: Remove the flag definition and related imports
   - **Usage sites**: Remove conditional logic, default to the new behavior, clean up related imports
   - **Test files**: Remove tests covering the 'disabled' state; update remaining ones; clean up mocks and imports
   - **Configuration files**: Remove entries related to the feature flag

5. **Re-run a full-text search** to ensure all references and imports are removed.

6. **Clean up** now-unused variables or functions introduced solely for the flag.

7. **Double-check** for any leftover imports or dead code.

8. **Commit only the affected files** (do NOT use `git add .`):
   ```
   git commit -m "chore(flag-cleanup): remove <flag-key> flag from codebase"
   ```
   The commit message should explain the flag was fully rolled out and the new behavior is now default.

9. **Push the branch**: `git push -u origin HEAD`

10. **Open a PR**: `gh pr create --title "chore: remove <flag-key> feature flag" --body "..."`
