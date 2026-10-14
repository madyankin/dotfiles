---
name: backlog
description: Park findings noticed in passing — bugs, dead code, stale docs, missing tests outside the current task — in a per-repo backlog file, and triage that backlog later. Use proactively, without being asked, whenever you notice something worth fixing that is out of scope for the current change. Also use when the user says "add to backlog", "запиши на потом", "запиши в бэклог", "разбери бэклог", "what's in the backlog", or invokes /backlog.
---

# Backlog

"By the way, I also noticed…" findings get lost in chat or bloat the current change. This skill
puts each one in a file in one command and keeps the current task on track. Triage happens
later, in its own pass.

Script: `scripts/backlog.py` (stdlib only). Run it with `python3 -I`.

```bash
B=~/.config/agents/skills/backlog/scripts/backlog.py
python3 -I $B add "<finding>" --where path/to/file.rb:42
python3 -I $B list            # this repo, numbered
python3 -I $B list --all      # every repo with open items
python3 -I $B done 3 --note "fixed in fix/foo"
python3 -I $B drop 2 --note "not a bug: X"
python3 -I $B path
```

Files: `~/.config/agents/backlog/<owner>-<repo>.md`, from the `origin` remote, so all worktrees
and clones share one file. A repo without a remote uses its folder name. Outside a repo it is
`_global.md`. `--slug <name>` writes to a named file regardless of cwd. The directory is local
and ignored by yadm. The script manages the file; edit only item lines by hand.

## Capture

Capture when all of these hold:

- It is real and concrete: you saw it in code, logs, or output, not a hunch.
- It is out of scope for the current task.
- It is more than a one-line fix you can make right now without widening the diff.

Write one sentence: symptom + why it matters. Put the locator in `--where`, not in the text.
The same text at the same place bumps `(seen N×)` instead of adding a duplicate, so reuse the
earlier wording when you meet the same thing again.

Then tell the user one line and go on with the task:

```
→ backlog: N+1 in Foo#bars on the index page (app/models/foo.rb:42)
```

Do not fix it inline. Do not stop to discuss it. Vague code-smell notes do not go in: if you
cannot say what breaks or what it costs, skip it.

## Triage

On `/backlog`, "разбери бэклог", or a request to review it:

1. `list` (or `list --all` if the user asks across repos).
2. Re-check each item against the current code. An item that is already fixed gets `done` with
   a note saying where it was fixed.
3. Propose one action per item, numbered, in one message:
   - **fix now**: say the branch name and how big the change is;
   - **ticket**: draft the ticket text for the user's tracker;
   - **drop**: give the reason;
   - **keep**: give the reason it can wait.
4. Apply only the items the user confirms. Never create branches, tickets, or commits without
   a yes. Close each applied item with `done` or `drop` and a note.

`_skills.md` holds skill-quality findings from the weekly self-heal report. Triage those with
`/improve-skill <name>` in history mode, not here.
