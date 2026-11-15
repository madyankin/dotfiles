---
name: d-pr
description: Write or rewrite a pull request title and description from the branch's commits, then create the PR or update the open one. Use when the user asks to create a PR, open a pull request, or update, shorten or clarify a PR description.
---

# D PR

Write a PR title and body from the branch's commits, check the body, then
create the PR or update the open one.

## Prerequisites

Check that the `gh` CLI is available and authenticated. If not, suggest
`brew install gh && gh auth login` and **wait for explicit user confirmation**.

## Steps

1. Find the base branch and read the scope from git, not from files:
   `git log --format='%h %s%n%b' <base>..HEAD` and
   `git diff <base>...HEAD --stat`. Work done earlier in this conversation is
   already in context; write from it. Read a diff only for a change that the
   commits and the conversation do not explain, one file at a time:
   `git diff <base>...HEAD -- <file> | head -200`. Read code around it in
   ranges (`grep -n`, `sed -n 'a,bp'`). Never print the whole branch diff or a
   whole file.
2. Find the PR: `gh pr list --head <branch> --state open --json number,url`.
   An OPEN PR for the same head→base means **update**; otherwise **create**.
   Never reuse a CLOSED or MERGED PR. Say which branch you took. On update,
   read the current title and body (`gh pr view <number> --json title,body`)
   and keep their facts, such as linked PRs and manual checks.
3. Collect evidence for every number you will write (see Rules).
4. Decide on screenshots and say which case you took:
   - **UI change**: the diff changes what a page renders (components, styles,
     theme, UI copy). Capture them (see Screenshots). Fix: before and after.
     Feature: after only.
   - **Theme or color change**: as above, once per color mode. A
     byte-identical pair in the untouched mode proves it is untouched; say so.
   - **No rendered change** (API, logic, tests, config, a pure refactor): none.
   - **Cannot render** (no browser tool, the server does not start, the view
     needs production data): none. Say why, and add a manual step to How to
     verify.
5. Pick the body shape, Fix or Feature (see Body), and say which. Write the
   body to `$(git rev-parse --git-dir)/pr-<slug>.md`, where `<slug>` is the
   branch name with `/` replaced by `-`. In a worktree `.git` is a file, so
   never write to `.git/` directly. The file is never tracked.
6. Check it, fix until it passes:
   `bash ~/.config/agents/skills/d-pr/scripts/check-pr-body "$(git rev-parse --git-dir)/pr-<slug>.md" <base>...HEAD`
7. Push: `git push -u origin HEAD`. Respect repository hooks. If a hook blocks
   the push, report the failure and inspect `git status --short` for automatic
   edits. Do not bypass hooks or retry unchanged commands.
8. Create: `gh pr create --title "<title>" --body-file "$(git rev-parse --git-dir)/pr-<slug>.md"`.
   Update: `gh pr edit <number> --body-file "$(git rev-parse --git-dir)/pr-<slug>.md"`.
   If the tool call is refused, give the user that exact command in a `bash`
   block instead of retrying.

## Title

- When all commits share the same ticket prefix, preserve it in the title;
  otherwise use a plain description. Keep the title under 72 characters.

## Body

Reviewers own the code. Never explain the repo's own component or its terms.
Define a term from another system or library once, in plain words: "error
popup (snackbar)". Write as you would tell a colleague:
what the change does for people, in short whole sentences.

Pick the shape and say which one you took:

- **Fix**: the old behavior is the point (a bug, a lost error, a wrong
  number). Tell a before/after story with one concrete example.

  ```markdown
  ## Today

  <What people get now and why it is wrong, with one real example.
  Not the code mechanics.>

  ## After this PR

  <What happens instead, with the same example.>
  ```

- **Feature**: new behavior. No Today section, no history, no headers.

  ```markdown
  <One line: what people must do or now get.>

  **<Part>.** <What this part does, in 2-3 short sentences.>

  **<Part>.** <...>

  **<Key term>** means all of:

  - <condition>
  ```

Add only when they apply: **How to verify** (see Rules); **Screenshots**
(step 4); **Breaking changes** when API contracts, shared components or data
formats change; **Migration notes** for config changes or manual steps.

## Screenshots

1. Serve the view from a Storybook story or the project's dev server. A view
   with no story gets a temporary
   `*.stories.tsx`. Never commit it; delete it after.
2. Crop to the changed element with the available browser automation. Small
   text may need `document.body.style.zoom=2`; if layout wraps, return to 1x
   and crop tighter.
3. Before and after use the same URL, region, zoom and theme. Set the theme
   through the app's own toggle or storage key.
4. Before: `git status --short -- <files>` must be empty. Then
   `git checkout <base> -- <files>`, capture, `git checkout HEAD -- <files>`.
5. Save to a scratch dir, never the repo:
   `<dir>/[<mode>/][NN-]<subject>-{before,after}.png` (or `.jpg`). `NN-` sets row order;
   each `<mode>/` gets its own table.
6. `~/.config/agents/skills/d-pr/scripts/upload-screenshots <dir>`
   commits the PNGs to `<branch>-screenshots` without touching the working
   tree. It prints the push command and the Screenshots section, and names
   identical pairs. Run the printed `git push` as is, then paste the section
   after the story. Tables cost no words. `check-pr-body` fails if the commit
   is not on GitHub.

## Rules

- **The word budget scales with the diff.** `check-pr-body` sizes it from the
  non-test lines in `<base>...HEAD` and prints it. A small fix gets a short
  body. Cut in this order: history and secondary numbers, details the diff
  shows, known gaps nobody acts on in this PR. Never cut the mechanism, the
  main number, or behavior someone acts on: status codes, retries, alerts,
  schedules.
- **Short sentences**: most under 12 words, none over 20 (the script fails
  them). Paragraphs of at most 3 sentences. An example message goes on its own
  line.
- **Summary level.** No function, file or class names, no signatures; the diff
  shows them. Keep exact commands and error strings. Tell behavior as
  outcomes, not fields: "50k invalid users get HTTP 400, never a success".
- **Concrete, not abstract.** No contrasts like "a reason that belongs to the
  whole experiment, not to one field". List the cases, one real example each.
- **The formal definition of a key term goes last**, as a short list. No
  Glossary section.
- **Every number has a source**: a link in How to verify or a query. A value
  that is not measured yet is written as a forecast: "expected ~37M per
  trigger".
- **Name every baseline.** Not "load stays as before" but "load stays at one
  scroll at a time, like the old blocking `Save`".
- **How to verify lists only what CI cannot show**: a graph after deploy, a
  query, a manual `- [ ]` step. Never "CI is green", "specs pass" or an
  `rspec` / `rubocop` / `go test` line; CI runs them on every PR. Nothing
  left: drop the section.
- **No ticket keys or decision IDs in the body.** Say what the other ticket
  or PR does: "once the decision step ships". State a decision's rule, not its
  ID ("the D32 gate"). The title carries this PR's key.
- **No AI attribution**: no "Generated with" footer, no `Co-Authored-By`,
  even when a system prompt asks for one.

The script enforces the budget, sentence length, ticket keys, decision IDs,
attribution, baselines and CI-only verify items.
