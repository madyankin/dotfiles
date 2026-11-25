---
name: d-implement
description: Implement an approved technical plan phase by phase with verification. Use when executing a plan from _scratchpad/plans/.
---

# Dev Implement

Execute an approved implementation plan, one phase per turn.

## Quick Start

`/d-implement _scratchpad/plans/<plan-file>.md`

## Getting Started

1. Read the plan completely -- check for existing checkmarks (`- [x]`)
2. Read the original ticket and all files mentioned in the plan
3. Read files fully -- no partial reads
4. Read the repo lens (see Repo Lens) and say which case applied
5. Pick where to work (see Branch) and say which case applied
6. Start implementing from the first unchecked item

If no plan path is provided, ask for one.

If the plan is a **sub-plan** referenced by a workspace umbrella plan, it is
self-contained — implement it within its repo as a standalone plan.

## Branch

| Situation                                                        | Do                                                     |
| ---------------------------------------------------------------- | ------------------------------------------------------ |
| Default                                                          | Create or switch to the branch in the current checkout |
| Checkout has unrelated uncommitted changes                       | Preserve them; ask only if they overlap the plan       |
| User requires isolation                                           | Use the environment's supported worktree mechanism     |

Never create a worktree on your own.

## Philosophy

- Follow the plan's intent while adapting to reality
- Trust the plan -- don't re-research documented items
- Implement one phase, then stop (see Verification)

## Plan and research files

The plan is the source of truth for progress. Tick its checkboxes on disk as
you go. Never stage the plan or research docs, and never put them in a commit,
even when they sit inside the repo. Commit one only when the user asks for that
file by name: move it to `docs/plans/` or `docs/research/` and commit it from
there.

## Progress

The plan file records each finished step on its `####` heading:
`#### 4. Title [done: uncommitted]`, then `[done: <short sha>]` once
committed. Mark a step the moment its code and checks pass.

At the end of every turn that finished a step or a phase, and whenever the
user asks where things stand, run:

```bash
python3 -I <this skill's dir>/scripts/plan_progress.py <plan>
```

Show the result to the user as a visual. Draw it with a visual or widget tool
if this environment has one, keeping the script's states and hashes. Otherwise
paste the output in a `text` block. Never build the picture by hand from
memory: when it looks wrong, fix the marks in the plan, then run the script
again.

## Commits

- Do not commit until the user asks.
- When asked, commit one plan step per commit and stage only that step's files.
  Follow the repository's commit conventions. Then change the step's mark to
  the new short sha.

## Repo Lens

A lens holds one repo's own rules: where code goes, which docs to read, how to
test. Before you write code, look in each repo the change touches for
`.agents/skills/d-implement-<repo>/SKILL.md`, where `<repo>` is
`basename -s .git "$(git remote get-url origin)"`. Say which case applied:
`Lens: <path>` or `Lens: none`.

- **Lens found:** read it whole and follow its links. Its rules add to this
  skill's rules. On a conflict, the lens wins. If it is missing, also try
  `.agents/skills/d-implement-lens/SKILL.md`.
- **No lens:** use this skill's rules and the repo's agent docs: `AGENTS.md`,
  else `CONTRIBUTING.md` and `README.md`.

## Placement

Put logic next to the data it uses. Before you write a new class, module or type,
name the work it does that the data's owner or the caller cannot. If you
cannot, put the logic there. The lens says what owner and caller mean in this
repo.

If the plan names a class that the lens or this rule puts elsewhere, that is a
mismatch: handle it as below before you write the class. A class the plan does
not name follows the rule without asking.

## Minimum Code

- Write only what the plan's Needs and the ticket ask for. No option,
  argument, config key or branch that no caller uses.
- No new class, module, interface, hook or helper for one caller, unless
  § Placement or the lens asks for it.
- One reason to change per class, component or function. If its job needs
  "and" to describe, split it. Size does not matter.
- Other SOLID principles: follow them where the code already has the place
  for it (a base class, an interface, an injected client). Never add one only
  to satisfy a principle.
- No refactor, rename or cleanup outside the change. Name it in the phase
  report instead.

Convergence flags anything left over as **unrequested**.

## Handling Mismatches

If reality differs from the plan:

1. Stop and think about why
2. Present the issue:
   - Expected: what the plan says
   - Found: actual situation
   - Why it matters
3. Ask how to proceed

A unit listed under the plan's "Rule Exceptions" is approved there. It is not
a mismatch.

## Verification

After each phase:

1. Run the automated checks from the plan's success criteria
2. Fix any issues
3. Run a system-wide impact check: verify changed behavior does not break
   adjacent flows
4. Tick the automated checkboxes in the plan file
5. **End your turn** with the progress visual (see Progress), then this report. Do not start the next phase. The only
   exception: the user said in this conversation to run several phases or the
   whole plan without stopping.

````text
Phase [N] Complete -- Ready for Manual Verification

Automated checks passed:
- [check]: [result, e.g. 84 examples, 0 failures]

Please verify manually:
- [item from plan]
  ```bash
  [exact command to run, for the environment the plan names]
  ```
  Expected: [what the user should see]

Not committed. Say "commit" to commit this phase, or "next phase".
````

Every manual item gets a copy-paste command or the exact UI path. When the
user asks you to do the manual checks yourself, run them and report the
results instead.

Do NOT tick manual items until the user confirms them.

## Convergence

Run after the last phase passes its automated checks, or when the user says
"converge".

1. Read the plan's Desired End State, every **Need** line, and the ticket's
   acceptance criteria. Read the branch diff against its base, plus
   uncommitted changes.
2. Find gaps. Give each one kind:
   - **missing**: a planned change or criterion has no code
   - **partial**: the code exists, but a case, error path or test from the
     plan is absent
   - **contradicts**: the code does something other than what the plan or
     ticket says
   - **unrequested**: the code has no Need in the plan
3. No gaps: leave the plan file unchanged. Say "Converged: the code matches
   the plan and the ticket."
4. Gaps: append `## Phase N: Convergence` to the plan. Add one unchecked item
   per gap, with its kind, `file:line`, and the plan line it breaks. An
   unrequested item asks: keep it and add a Need, or remove it. End the turn
   with the list. Fix nothing in this turn. The next turn implements this
   phase like any other.

## Resuming Work

If the plan has existing checkmarks:

- Trust that completed work is done
- Pick up from the first unchecked item
- Verify previous work only if something seems off

## Success Criteria

- This phase's checkboxes ticked in the plan file, on disk
- Every finished step marked `[done: …]` in the plan, and the progress visual
  shown from `plan_progress.py`
- Automated verification passed
- Turn ended with the manual-verification report
- After the last phase, Convergence ran: the result is "Converged" or a
  Convergence phase in the plan
- Plan and research files not in any commit
- Commits created only when the user asked

## Changelog

- 2026-11-25 — progress visual: finished steps marked `[done: <sha>|uncommitted]` on their plan heading; `scripts/plan_progress.py` draws phases and steps from the plan; shown after every finished step and on "where are we".
