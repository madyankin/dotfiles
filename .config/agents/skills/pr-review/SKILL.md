---
name: pr-review
description: Review someone else's pull request together with the user — find what is wrong and prove it, walk the findings one by one with current and proposed code, draft each comment in the user's own voice, put approved ones into the user's pending GitHub review, and submit only when told. Use when the user asks to review a PR, to go through findings one by one, to draft or post review comments, to check a PR for SOLID/SRP or redundant specs, or says "сделай ревью", "давай по одному", "драфт коммента", "запости", "отправь ревью".
---

# PR Review

The user reviews; you do the legwork. They decide every comment. Your job is to find real
problems, prove them, and turn the ones they accept into comments that read as theirs.

Five phases. Say which one you are in when it changes.

| Phase | Ends when |
|---|---|
| 1. Review | Findings list with proof, ordered by what breaks |
| 2. Walkthrough | Every finding is posted, skipped or merged |
| 3. Post | Each accepted comment sits in the user's pending review |
| 4. Submit | The user names the event; the review is sent |
| 5. Follow-ups | Extra passes the user asks for (specs, design, a line they want explained) |

## 1. Review

Gather before judging:

- The diff, every existing review and comment, including the user's own pending review. Do
  not repeat a point already made.
- The repo's rules: `AGENTS.md`, `CONTRIBUTING.md`, any review lens under `.agents/skills/`.
- The PR head in a clean worktree. Run its lint and the changed specs there, and again merged
  with the current base branch when the PR is behind.
- Other open PRs that touch the same files or interface: `gh pr list --search "<path>" --state open`.
- A closed or earlier attempt at the same feature, when the user points at one. Name what to
  borrow and what not to, with the reason.

Rules for a finding:

- **Prove it.** A run (a throwaway spec at the PR head, deleted afterwards) or the exact code
  lines. Say "not proved" when you have neither.
- **Rate it by what breaks.** Name the input that makes it fail. No such input means a Nit
  about structure, however wrong the code looks.
- **"Differs from X" needs X.** Read X (another app, the old path, a sibling tool) on its
  default branch. Say whether X enforces the rule or only hints. Matching a hint is a
  Suggestion at most.
- **A contract, not a choice.** When two open PRs return different shapes from one method,
  flag the contract once, addressed to whichever merges second.

What to look for beyond bugs:

| Smell | Ask for |
|---|---|
| Code outside a class flips its state or reads its error text to learn what it knows | A method on that class; match error types or options, never message text |
| A check run a second time to get data the first run already had | Keep the data from the first run |
| The same hash shape built in several places, stored or compared | A typed value object. Kinds one class creates nest inside that class; only the shared base is global. No name that shadows a core constant |
| One class doing several jobs; the same pair of arguments passed down a chain of methods | An object that holds that pair, one job per class |
| An empty value standing in for "not loaded" (`items: []`) | Leave the key out |
| A base method whose keyword names are swapped for `**` to quiet a linter | Keep the names: they are the contract. Disable the cop inline |
| Two saves of the same record to compute two things | One transaction or savepoint, both computed inside |

Specs:

- Name the branch each new example covers. Two examples on one branch is a duplicate.
- A stub that raises an error the real code never raises tests nothing.
- Examples that differ only in input and expected value are one table.
- A side-effect check (`count` unchanged) once per code path, not on every example.

Output: one numbered list, most severe first. For each: file:line on the PR head, the failing
input or "structure", the proof.

## 2. Walkthrough

One finding per turn, as `n/N`. Recount when findings merge or drop.

Each turn shows:

1. The current code, quoted from the PR head, with path and line numbers.
2. The proposed code.
3. The draft comment.

Then stop and wait: post, skip, or change. Show code only during a walkthrough; elsewhere prose
is enough.

When the user asks "why do you think so", split what the code shows from what you inferred.
If you overstated, say so in one sentence and lower the severity.

When the user asks what a line does, trace it: where it is defined, every caller it reaches
(including ones outside the PR's purpose), and the edge cases. Then answer.

## 3. Drafting comments

Voice: read 10–20 of the user's recent review comments first.

```bash
gh api 'repos/<o>/<r>/pulls/comments?sort=created&direction=desc&per_page=100' \
  --jq '.[] | select(.user.login == "<login>") | .body'
```

Skip agent-signed ones. Then write:

- One to three plain sentences. "Let's …", "Can we …", "Nit: …". End with "like so:" and a
  code block.
- No headings, bullets or bold. No jargon ("collaborator", "invariant"). Plain words a
  teammate uses.
- Never link the lines the comment sits on.
- Every claim about other code carries a permalink on the claim phrase, pointing at the exact
  lines that prove it: `https://github.com/<o>/<r>/blob/<sha>/<path>#L<a>-L<b>`. Not the file,
  not the component. Check the numbers at that sha before linking:
  `git show <sha>:<path> | sed -n '<a>,<b>p'`.
- Anchor on changed lines. A line outside the diff cannot take a comment; pick the closest
  changed line and link the real one.

## 4. Posting

"Post" means add to the user's **pending** review on GitHub, where they see it at once.
Never a standalone comment: REST `POST .../pulls/<n>/comments` publishes immediately. Never a
local queue the user cannot see.

```bash
s=~/.config/agents/skills/pr-review/scripts/pending-review
bash "$s" add <pr> <path> <line|start-end> <body.md> [owner/repo]   # creates the pending review if missing
bash "$s" list <pr> [owner/repo]                                     # comment ids, path:line, first line
bash "$s" edit <comment id> <body.md>                                # REST cannot edit a pending comment
```

The script refuses lines outside the diff, retries GitHub's transient "Something went wrong",
and never submits. Add `--dry-run` to `add` to check an anchor without posting.

When a later decision changes the design, edit every earlier comment it touches so the review
reads as one design. List them first and show the changed code.

If comments already went out standalone by mistake: check for replies and reactions, ask, and
only then delete and re-add them to the pending review.

## 5. Submitting

Only when the user says so, with the event they name (`COMMENT`, `REQUEST_CHANGES`,
`APPROVE`). Before sending, check the PR is still open and the head sha is the one you
reviewed.

The body is one line per inline comment, most important first, plus one line for anything
that has no inline home (a cross-PR contract). No overview prose.

```bash
gh api repos/<o>/<r>/pulls/<pr>/reviews/<review id>/events -X POST \
  -f event=REQUEST_CHANGES -F body=@body.md
```

## Checking behaviour in a UI

When a finding is about what an app shows, check it in the browser:

- Screenshot each warning or error the moment it appears and send it.
- If the data looks like production, only read. Do not edit forms or save.
- Sign-in pages are the user's to complete.

## Never

- Post, edit or submit without the user's go for that step.
- Delete the user's published comments without checking replies and asking.
- Present an inference as proved, or a structural nit as a bug.
- Quote a line number you did not check at the linked sha.

## Changelog

- 2026-11-06 — created from a full PR review session: walkthrough with current/proposed code, voice, pending-review script, permalinks on claims, severity by failing input, design and spec checks.
