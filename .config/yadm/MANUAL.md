# Using these dotfiles

Day-to-day operation. The root `README.md` covers installing on a new machine,
what is deliberately untracked, and the footguns; this covers what you actually
type.

Everything goes through one command:

```bash
dot                 # grouped help — every subcommand with a one-line summary
dot commands        # the same list, flat
dot menu            # pick one with fzf, in the terminal you are already in
```

`dot` lives at `~/.config/yadm/bin/dot` and is on `PATH` as `~/.local/bin/dot`.
Subcommands are **files** in `bin/`: drop in `bin/dot-foo`, give it a
`# dot:summary=` comment, and it appears in the help, in `dot menu` and in
Alfred with nothing else to edit.

---

## Every day

| Command | What it does |
|---|---|
| `dot doctor` | Check the machine against the config. Run it when something feels off |
| `dot update` | brew, mas, mise, npm, nvim, tpm, zplug, and a `yadm pull` |
| `dot sync` | Commit and push the dotfiles now (also aliased `sync-dotfiles`) |
| `dot theme set <name>` | Switch the whole palette |
| `dot install` | The software wizard |

### `dot doctor`

Nine groups of checks, ~9 seconds. It exists because **every problem this repo
has actually had was drift, not a missing migration**: a crontab commented out
by hand, an app uninstalled from under its config, two version managers
fighting over the same shims. A run-once migration runner notices none of that;
a doctor notices all of it, every time.

```bash
dot doctor                  # everything
dot doctor --only runtimes  # one group (substring match on the filename)
dot doctor --fix            # offer the destructive one-shots, asking first
```

Checks live in `doctor.d/NN-name.sh`, one concern per file. Two allowlists stop
a permanently-warning check from training you to ignore it:

- `doctor.d/orphans.allow` — config directories kept without the app installed
  here. `aerospace` is in it: the window-manager decision is deferred, the toml
  is good, and Amethyst + Rectangle are what actually run.
- `doctor.d/packages.allow` — top-level formulae deliberately unmanaged.

### `dot update`

```bash
dot update                  # the lot
dot update --dry-run        # print every step's plan, change nothing
dot update --only nvim      # one step
dot update --skip brew
dot update --prune          # also brew cleanup
dot update --log            # what the last run found installed
```

Steps are `update.d/NN-name.sh`. Notes on the ones with sharp edges:

- **brew** deliberately does not pass `--greedy`. It would fight the apps that
  ship their own updaters (1Password, Chrome, Zed, Obsidian).
- **nvim** rewrites the *tracked* `lazy-lock.json`. That is the point: the next
  sync commits the new pins and the other machine gets the same plugin versions.
- **npm** installs each manifested package at `@latest` individually. A blanket
  `npm -g update` under a shimmed node is how a whole toolchain gets bricked.
- Before anything runs, `~/.local/state/dot/updates/<timestamp>/` records a
  `brew bundle dump`, `mise ls`, `npm ls -g` and `lazy-lock.json`. macOS has no
  selective snapshot worth using, and Arq owns real backups; this answers the
  question a snapshot is a proxy for — *what changed, and what do I pin back to*.

### Sync

`scripts/commit-and-push.sh` every two hours, now scheduled by a **launchd user
agent**, not cron. macOS cron runs outside the GUI session, so `yadm push` there
has no `SSH_AUTH_SOCK` and no keychain, and `/usr/sbin/cron` needs Full Disk
Access — which is the likely reason the crontab entry had been commented out by
hand. A `gui/$UID` agent has both, and a `StartInterval` missed while asleep
fires once on wake.

```bash
dot cron install                                          # load it
launchctl print gui/$UID/name.madyankin.dotfiles.sync     # is it armed
launchctl kickstart -p gui/$UID/name.madyankin.dotfiles.sync   # run it now
tail -f ~/.local/state/dot/sync.log
```

The plist is rendered from `launchd/*.plist.template` because **launchd does not
expand `$HOME`** — a literal plist would bake an absolute username into a public
repo.

---

## Themes

One palette per theme drives the terminal, tmux, the prompt, fzf, btop, htop,
mc, nvim, VS Code, Zed, the iTerm2 profile, Terminal.app and Ghostty's app icon.

```bash
dot theme list
dot theme set one
dot theme render                    # regenerate without switching
dot theme render --skip editors     # keep hand-tuned nvim/VS Code/Zed themes
dot theme doctor
dot background next
dot font list
dot font set "JetBrainsMono Nerd Font Mono" 15
dot theme render --only fonts        # just the font fan-out
```

Authoring a theme: `themes/README.md`. Short version — copy a directory, edit
the hex values, `dot theme set <name>`.

### How light/dark works, and why there is no daemon

**Both modes are always generated, and each app's own detection picks one.**
Ghostty, nvim, VS Code, Zed and iTerm2 all switch themselves. tmux, the p10k
prompt, fzf and `ls` are rendered in **ANSI indices 0–15 only, never hex** — the
terminal swaps its own palette when macOS flips, so those repaint in
already-open shells on the next redraw.

Consequence worth knowing: if you put a hex colour where an ANSI index belongs,
that thing stops following the system. `dot theme doctor` checks the prompt for
exactly this.

Two exceptions:

- **htop and mc** rewrite their own config on exit, so they are selected per
  launch by wrapper functions in `functions.zsh` via `HTOPRC` and `MC_SKIN`.
  That is also why htop's layout lives in the tracked `htoprc.base` and the
  generated files absorb the churn. Promote a layout change back with
  `theme.sh capture-htop`.
- **Terminal.app** has no light/dark awareness at all. It is the only thing that
  needs a push, and it is opt-in:

  ```bash
  dot theme install-agent     # 2s poll, sets Terminal.app's default profile
  dot theme uninstall-agent
  ```

  Already-open Terminal.app windows never retheme; only new ones.

### Two apps need a nudge after a palette edit

Ghostty caches its theme file — `Cmd+Shift+,`. Neovim — `:source $MYVIMRC` or
reopen. `theme.sh` prints this reminder after every render.

### Alfred is deliberately not themed

It stays on the imported **Alfred macOS Ventura** theme, bound to both the light
and dark slots, with Alfred's own `nativedarkmode` doing the adaptation. A
launcher tinted to editor colours looked wrong next to everything else.

---

## Agents

```bash
dot agent              # launch the default one
dot agent list         # * marks the default
dot agent set codex
dot agent prompt "review this diff"     # one-shot, in the current directory
dot agent usage        # sessions and tokens per agent per day
```

`dot agent usage` reports counts only — never a key, token value or account
identifier. That output ends up in pastes.

Your own aliases are untouched: `ca` is `claude --enable-auto-mode`, `cy` is
`claude --dangerously-skip-permissions`. Omarchy's `c`/`cx`/`cy` were **not**
ported precisely because `cy` already means something here.

---

## Alfred

Keyword `dot` lists every subcommand and runs it in Ghostty. `theme` is the
style menu. `agent <your task>` hands the task to the default agent.

The workflow is **generated** by `scripts/alfred-dot-workflow.py`, not
hand-built in Alfred's UI — an `info.plist` edited through the GUI is
unreviewable and drifts from the CLI within a month. The Script Filters call
`dot commands --json`, so they list whatever exists.

```bash
dot alfred workflow    # regenerate; Alfred picks it up on relaunch
```

Each Alfred launch opens a **new Ghostty instance**, not a window in the running
one: `open` discards `--args` without `-n`. Use `dot menu` when that matters.

The terminal action hands Ghostty `bin/dot-in-terminal` as a program to exec,
with the subcommand as plain argv. It must not use
`--initial-command="shell:…"`: Ghostty wraps that as
`login -flp <user> /bin/bash --noprofile --norc -c exec -l <string>`, and the
prepended `exec -l` replaces the shell with the first command — so a trailing
`; exec /bin/zsh -l` never runs and the window dies as soon as the command
finishes.

---

## Packages

Groups: `essentials`, `dev`, `work`, `personal`, `goose`. One
`packages/Brewfile.<group>` each.

```bash
dot install              # wizard
dot install --dry-run
```

Removal stays scoped — a package is uninstalled only when it appears in some
manifest *and* is absent from the current selection. It is the only thing
stopping a wizard run from clearing half the machine, so do not weaken it.

`dot doctor` reports drift in both directions. The installed→manifest side uses
`brew leaves` (top-level, ~46) rather than `brew list --formula` (~179, mostly
transitive dependencies that have no business in a manifest).

---

## Runtimes

**mise owns everything; asdf is gone.** Pins live in the tracked
`~/.config/mise/config.toml`. The key is `node`, not `nodejs` — the old
`~/.tool-versions` used the asdf spelling, which mise ignores, which is why
every runtime reported `(missing)` while asdf's shims quietly won.

Agent CLIs (codex, gemini-cli, pi, agent-browser) are mise **`npm:` backend**
tools, not `npm install -g`. A global installed under node 24 vanishes the
moment a project pins node 22, and `~/Code/.tool-versions` does exactly that.

Ruby stays on Homebrew, not mise — a mise ruby means a source build. Gems go to
`GEM_HOME=~/.gem` rather than `/opt/homebrew/lib/ruby/gems/<X.Y.0>/bin`, which
silently breaks on every ruby upgrade.

`mise activate` output is **not cacheable**: it bakes the current `PATH` into
`__MISE_ORIG_PATH`, so a cached copy would restore a stale PATH into every
future shell.

---

## Shell

~0.17s interactive startup, down from 0.65s. The win was taking zplug out of
the startup path: the framework cost 0.58s cold / 0.14s warm, while sourcing the
same 12 files it clones costs 0.07s. zplug is still installed and still owns
cloning and updating.

`plugins.zsh` has a load order that is **load-bearing**: fpath → compinit →
plugins (they call `compdef`) → syntax highlighting last (it wraps the ZLE
widgets everything else redefines). Adding an fpath entry after compinit makes
it invisible.

Editing `plugins.zsh` invalidates a marker keyed to its mtime, so the next
single shell re-verifies the clones. That one shell is slow; the rest are not.

### Two shell footguns added since the README was written

- **`$ZDOTDIR/.zshenv` now exists and sources `~/.zshenv`.** This is not a
  contradiction of "never source `~/.zshenv` from `.zshrc`" — different file,
  different problem. `~/.zshenv` exports `ZDOTDIR`, and once that is in the
  environment every *nested* zsh (a tmux pane, `zsh -c` from a script) reads
  `$ZDOTDIR/.zshenv` and never looks at `~/.zshenv` again. Without the shim
  those shells silently keep whatever PATH they inherited.
- **`~/.zshenv` is parsed by bash** (`commit-and-push.sh` sources it), and bash
  parses the whole file even inside an `if [ -n "$ZSH_VERSION" ]` branch it never
  takes. So zsh-only syntax there is a bash *parse error*; the PATH-pruning glob
  is hidden behind `eval '…'` for that reason. The file ends in `:` so sourcing
  it from bash still returns 0.

`./bin` is no longer on `PATH`. It put the `bin/` of whatever repo you were
standing in ahead of your own commands, including repos cloned by agents. Use
direnv's `PATH_add bin` per project; direnv is hooked now.

---

## Terminal

Ghostty is the daily driver, iTerm2 remains installed as a fallback with its own
tracked plist.

`~/.config/ghostty/config` is tracked. Its theme files and `icon.conf` are
generated and gitignored. Three settings are there for non-obvious reasons:

- `term = xterm-256color` — Ghostty's own `xterm-ghostty` terminfo is absent on
  every remote host, which breaks `ssh` and `clear` confusingly.
- `shell-integration-features = no-cursor` — with the `cursor` feature on, the
  shell forces a bar at the prompt "regardless of this configuration", so
  `cursor-style` would only apply mid-command.
- `adjust-underline-thickness` — there is no underline-cursor-specific thickness
  option; the underline cursor uses the font's underline metric, so this also
  thickens genuinely underlined text. These adjustments are **deltas**: `200%`
  means three times the original, and `1px` is invalid syntax that Ghostty drops
  silently.

`macos-titlebar-style = hidden` costs the traffic lights — Ghostty always hides
them in that mode. `Cmd+W` to close, drag the terminal body to move.

---

## When something breaks

```bash
dot doctor                      # start here
dot doctor --fix                # if it offers something
dot theme render                # colours look wrong
yadm status --short             # what is uncommitted
```

Not tracked and recoverable only by hand: see the README's table. Nothing in
`~/.ssh`, `~/.gnupg`, `~/.aws` or `~/.npmrc` is in this repo, and the
`pre_commit` hook refuses to commit anything credential-shaped — which matters
because the sync commits unattended.
