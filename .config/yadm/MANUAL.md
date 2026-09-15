# Dotfiles manual

How this machine is operated. The root `README.md` covers installing from
scratch, what is deliberately untracked, and the repository's own hazards.
This is the reference for everything you type afterwards.

Read it in a terminal with `dot manual`, or by keyword `manual` in Alfred.

## Contents

- [The `dot` command](#the-dot-command) — one entry point, files as subcommands
- [Daily operations](#daily-operations) — converge, doctor, update, sync
- [Themes](#themes) — one palette, every app, light and dark
- [Terminal](#terminal) — Ghostty, and the settings with non-obvious reasons
- [Shell](#shell) — load order, and the rules that bite
- [Runtimes](#runtimes) — mise
- [Packages](#packages) — groups and scoped removal
- [Agents](#agents) — default agent, one-shot prompts, usage
- [Alfred](#alfred) — the generated workflow
- [Layout](#layout) — where everything lives
- [Recovery](#recovery)

---

## The `dot` command

```bash
dot                 # grouped help: every subcommand with a one-line summary
dot commands        # the same list, flat; --json feeds Alfred
dot menu            # pick one with fzf, in the terminal you are already in
dot manual          # this document
```

`dot` lives at `~/.config/yadm/bin/dot`, on `PATH` as `~/.local/bin/dot`
through a relative symlink.

Subcommands are **files**. `dot a b c` resolves by longest prefix to an
executable `bin/dot-a-b-c`, else `bin/dot-a-b`, else `bin/dot-a`, passing the
rest as argv. Adding one is adding a file with a `# dot:summary=` comment: it
appears in the help, in `dot menu` and in Alfred with nothing central to edit.

Everything in `bin/`, `lib/`, `scripts/`, `doctor.d/` and `update.d/` is bash
3.2 — no associative arrays, no `${arr[-1]}`, no `mapfile`. `functions.zsh` is
the one intentional zsh file.

---

## Daily operations

| Command | Use it when |
|---|---|
| `dot converge` | This machine has pulled config it has not applied |
| `dot doctor` | Something feels off |
| `dot update` | Updating brew, mas, mise, npm, nvim, tpm, zplug |
| `dot sync` | You want the dotfiles committed and pushed now |
| `dot install` | Adding or removing managed software |
| `dot theme set <name>` | Changing the palette |

### converge

`yadm pull` moves **tracked** files only. Everything generated or linked is
gitignored, because it is an output — so a machine that has only pulled is
missing all of it:

- `~/.local/bin/dot`, so `dot` is not on `PATH`
- the `yadm alt` output, **including `.config/zsh/.zshrc`** — the shell keeps
  running its previous configuration, which is the most confusing symptom
- every colour file: Ghostty's themes and `icon.conf`, `tmux/theme.conf`,
  `p10k-colors.zsh`, `fzf-colors.zsh`, the nvim colorschemes, btop, htop, the
  mc skins, the iTerm2 dynamic profile, the VS Code theme extension
- the agent and editor symlinks

```bash
~/.config/yadm/bin/dot converge   # full path, when dot is not on PATH yet
dot converge                      # afterwards
```

It is the idempotent subset of bootstrap — `yadm alt`, the CLI symlink, agent
and editor links, the iTerm2 prefs pointer, a full theme render. No macOS
defaults, no install wizard, no scheduler, so it is safe unattended: the sync
runs it after every pull, and it writes nothing when already in sync.

Three things it leaves alone, because they need a decision or a download:

```bash
dot install          # packages named in the Brewfiles
dot update           # mise runtimes, editor and shell plugins
dot cron install     # opt this machine into the periodic sync
```

### doctor

Ten groups of checks, a few seconds. The design choice behind it: this
configuration converges rather than migrating. Every setup script drives the
machine toward a desired state instead of applying a one-way delta, and a
doctor is the read-only half of that idea — it catches **drift**, which a
run-once migration runner cannot see at all.

```bash
dot doctor                  # everything
dot doctor --only runtimes  # one group; substring match on the filename
dot doctor --fix            # offer the destructive one-shots, asking first
```

Checks are `doctor.d/NN-name.sh`, one concern per file, each exiting non-zero
on failure. Two allowlists keep a permanently-warning check from training you
to ignore it:

- `doctor.d/orphans.allow` — config directories kept without the app installed
  on this machine. Normal in a two-machine setup.
- `doctor.d/packages.allow` — top-level formulae deliberately unmanaged.

### update

```bash
dot update                  # everything
dot update --dry-run        # print each step's plan, change nothing
dot update --only nvim
dot update --skip brew
dot update --prune          # also brew cleanup
dot update --log            # what the last run found installed
```

Steps are `update.d/NN-name.sh`. The ones with sharp edges:

- **brew** does not pass `--greedy`; it fights apps that ship their own
  updaters (1Password, Chrome, Zed, Obsidian).
- **nvim** rewrites the *tracked* `lazy-lock.json`, so the next sync ships the
  same plugin versions to the other machine.
- **npm** installs each manifested package at `@latest` individually. A blanket
  `npm -g update` under a shimmed node can break a whole toolchain at once.

Before any step runs, `~/.local/state/dot/updates/<timestamp>/` records a
`brew bundle dump`, `mise ls`, `npm ls -g` and `lazy-lock.json` — enough to
answer *what changed, and what do I pin back to*. macOS has no selective
snapshot worth relying on; Arq owns real backups.

`dot update` pulls, then re-execs the step runner as a fresh process, so a pull
that changed the steps runs the new ones.

### sync

> `dot sync` stages and commits everything in scope under a generic
> `chore(sync)` message. Commit anything that deserves a real message first.

`scripts/commit-and-push.sh` runs every two hours from a **launchd user
agent**. It has to be launchd rather than cron: macOS cron runs outside the GUI
session, so `yadm push` there has no `SSH_AUTH_SOCK` and no keychain, and
`/usr/sbin/cron` needs Full Disk Access. A `gui/$UID` agent has both, and a
`StartInterval` missed while asleep fires once on wake.

```bash
dot cron install                                             # load it
launchctl print gui/$UID/name.madyankin.dotfiles.sync        # armed?
launchctl kickstart -p gui/$UID/name.madyankin.dotfiles.sync # run now
tail -f ~/.local/state/dot/sync.log
```

Plists are rendered from `launchd/*.plist.template`, because **launchd does not
expand `$HOME`** and a literal plist would commit an absolute username to a
public repository.

Staging is two-part, because the work tree is `$HOME`: `yadm add -u` for
tracked files anywhere, plus a scoped `add -A` over the directories where new
dotfiles legitimately appear. The Alfred workflows directory is excluded from
`add -u` and re-added with `--ignore-removal`: a workflow missing there means
*not installed on this machine*, not *deleted*.

---

## Themes

One palette drives the terminal, tmux, the prompt, fzf, btop, htop, mc, nvim,
VS Code, Zed, the iTerm2 profile, Terminal.app and Ghostty's app icon.

```bash
dot theme list                      # * marks active
dot theme set one
dot theme render                    # regenerate without switching
dot theme render --skip editors     # keep hand-tuned nvim/VS Code/Zed themes
dot theme render --only fonts
dot theme doctor
dot background next
dot font list
dot font set "JetBrainsMono Nerd Font Mono" 15
```

Authoring: `themes/README.md`. In short — copy a theme directory, edit the hex
values, `dot theme set <name>`.

### Light and dark, without a daemon

**Both modes are always generated, and each application's own detection picks
one.** Ghostty, nvim, VS Code, Zed and iTerm2 all switch themselves.

tmux, the prompt, fzf and `ls` are rendered in **ANSI indices 0–15 only, never
hex**. The terminal swaps its own palette when macOS flips appearance, so those
repaint in already-open shells on the next redraw. The constraint follows: a
hex colour where an ANSI index belongs stops that tool following the system.
`dot theme doctor` checks the prompt for it.

Two exceptions:

- **htop and mc** rewrite their own config on exit, so generating those files
  directly would fight the application. Wrapper functions in `functions.zsh`
  select a generated file per launch through `HTOPRC` and `MC_SKIN`. htop's
  layout therefore lives in the tracked `htoprc.base`, and the generated copies
  absorb the churn; promote a layout change back with `theme.sh capture-htop`.
- **Terminal.app** has no light/dark awareness, so it is the only target that
  needs a push, and it is opt-in:

  ```bash
  dot theme install-agent      # 2s poll; sets Terminal.app's default profile
  dot theme uninstall-agent
  ```

  Only new Terminal.app windows pick up a change.

Two applications need a nudge after a palette edit: Ghostty caches its theme
file (`Cmd+Shift+,`), and Neovim needs `:source $MYVIMRC` or a restart.
`theme.sh` prints this after every render.

**Alfred is not themed.** It uses the imported *Alfred macOS Ventura* theme,
bound to both the light and dark slots, with Alfred's own `nativedarkmode`
doing the adaptation.

---

## Terminal

Ghostty is the daily driver; iTerm2 stays installed as a fallback with its own
tracked plist. `~/.config/ghostty/config` is tracked, its theme files and
`icon.conf` are generated.

Four settings exist for reasons worth knowing:

- `term = xterm-256color` — Ghostty's own `xterm-ghostty` terminfo is absent on
  remote hosts, which breaks `ssh` and `clear` confusingly.
- `shell-integration-features = no-cursor` — with the `cursor` feature enabled
  the shell forces a bar at the prompt *regardless of `cursor-style`*, so the
  configured cursor would only appear mid-command.
- `adjust-underline-thickness` — there is no underline-cursor thickness option;
  the underline cursor uses the font's underline metric, so this also thickens
  genuinely underlined text. These adjustments are **deltas**: `200%` means
  three times the original. Integers and percentages only — `1px` is invalid
  and is dropped silently.
- `macos-titlebar-style = hidden` — costs the traffic lights, which Ghostty
  always hides in this mode. `Cmd+W` closes; drag the terminal body to move.

---

## Shell

zsh with `ZDOTDIR=~/.config/zsh`, powerlevel10k, and oh-my-zsh libraries and
plugins sourced directly. Interactive startup is ~0.17s.

zplug is installed and owns **cloning and updating** the plugin repositories,
but is not in the startup path: sourcing the twelve files it clones costs a
fraction of loading the framework. `dot update` runs `zplug update`.

`plugins.zsh` has a **load-bearing order**:

1. `fpath` — every directory holding `_completion` files
2. `compinit` — it scans `fpath`; anything added afterwards is invisible
3. plugins — they call `compdef`, which needs `compinit` already run
4. syntax highlighting **last** — it wraps the ZLE widgets the others redefine

`lib/functions.zsh` and `lib/git.zsh` are sourced explicitly and before the
plugins: they define `take`, `mkcd`, `omz_urlencode`, `git_current_branch` and
`parse_git_dirty`, which git aliases such as `ggpush` and `gpsup` call at
runtime.

Editing `plugins.zsh` invalidates a marker keyed to its mtime, so exactly one
subsequent shell re-verifies the clones. That shell is slow; the rest are not.

### Rules that bite

- **`$ZDOTDIR/.zshenv` exists and sources `~/.zshenv`.** `~/.zshenv` exports
  `ZDOTDIR`, and once that is in the environment every *nested* zsh — a tmux
  pane, `zsh -c` from a script — reads `$ZDOTDIR/.zshenv` and never looks at
  `~/.zshenv` again. Without the shim those shells silently keep whatever
  `PATH` they inherited. This is not the same thing as sourcing `~/.zshenv`
  from `.zshrc`, which remains wrong.
- **`~/.zshenv` is parsed by bash**, because `commit-and-push.sh` sources it —
  and bash parses the entire file even inside an `if [ -n "$ZSH_VERSION" ]`
  branch it never takes. zsh-only syntax there is a bash *parse error*, which
  is why the `PATH`-pruning glob hides behind `eval '…'`. The file ends in `:`
  so sourcing it from bash returns 0.
- **`./bin` is not on `PATH`**, deliberately: it would put the `bin/` of
  whatever repository you are standing in ahead of your own commands,
  including repositories cloned by agents. direnv's `PATH_add bin` is the
  opt-in per project; direnv is hooked after mise.
- `PATH` is built in a single assignment, highest priority first, and entries
  whose directory does not exist are pruned.

---

## Runtimes

**mise owns the runtimes.** Pins live in the tracked
`~/.config/mise/config.toml`, where the key is `node` — not asdf's `nodejs`,
which mise ignores silently.

Agent CLIs (codex, gemini-cli, pi, agent-browser) are mise **`npm:` backend**
tools rather than npm globals. An npm global belongs to one node version and
disappears the moment a project pins another, which `~/Code/.tool-versions`
does.

Ruby comes from Homebrew, not mise — a mise ruby means a source build. Gems go
to `GEM_HOME=~/.gem`, not `/opt/homebrew/lib/ruby/gems/<X.Y.0>/bin`, which
breaks on every ruby upgrade.

`mise activate` output is **not cacheable**: it bakes the current `PATH` into
`__MISE_ORIG_PATH`, so a cached copy restores a stale `PATH` into every future
shell.

---

## Packages

Groups `essentials`, `dev`, `work`, `personal`, `goose`, one
`packages/Brewfile.<group>` each.

```bash
dot install              # live fzf picker over every package
dot install --dry-run    # print the plan, change nothing
dot install --classic    # the numeric-menu fallback
```

The picker is one flat searchable list of all ~95 packages across every group.
**space** toggles a package and the list redraws with the new checkbox;
**enter** applies; **esc** cancels. The preview pane shows the resulting plan —
what would be installed and removed — and refreshes on every toggle, so the
consequences are visible while you choose.

A package that is installed and named by a manifest but missing from the
selection is **adopted** before the picker opens. Otherwise it would appear as
a proposed removal purely because the selection file predates the manifest
entry. Deselecting it in the picker still removes it.

fzf backs every "which one?" prompt for the same reason — `dot theme set`,
`dot font set` and `dot agent set` all open a picker when called with no
argument, and `dot doctor --fix` offers its fixes as a multi-select rather than
a chain of y/N questions. With no controlling terminal every one of them
reports and exits instead of prompting: fzf does not fail without a tty, it
hangs.

**Removal is scoped.** A package is uninstalled only when it appears in some
group's manifest *and* is absent from the current selection. It is the only
thing standing between a wizard run and half the machine, so do not weaken it.

Manifest names must be **canonical**: `install.sh` compares against
`brew list --formula`, which prints canonical names, so an alias such as
`delta` or `mc` never matches and reports itself missing forever. `dot doctor`
checks for this, and reports drift in both directions — using `brew leaves`
for the installed side, since `brew list --formula` is mostly transitive
dependencies that have no business in a manifest.

---

## Agents

```bash
dot agent                               # launch the default
dot agent list                          # * marks the default
dot agent set codex
dot agent prompt "review this diff"     # one-shot, in the current directory
dot agent usage                         # sessions and tokens per agent per day
```

`dot agent usage` prints counts only — never a key, token value or account
identifier, because that output ends up in pastes.

Shell aliases are separate and unaffected: `ca` is `claude --enable-auto-mode`,
`cy` is `claude --dangerously-skip-permissions`.

---

## Alfred

| Keyword | What it does |
|---|---|
| `dot` | every subcommand, run in Ghostty |
| `theme` | theme, background and font — the style menu |
| `agent <task>` | hands the task to the default coding agent |
| `tw [dir]` | new Ghostty window in a directory |
| `manual` | a section of this document |

`tw` offers the front Finder window first, then `$HOME`, then an exact path if
the query is one, and otherwise directories matching the query found with `fd`
under whichever of `~/Code`, `~/Projects`, `~/Documents` and `~/.config`
exist. `dot term [dir|finder]` is the same thing from the shell.

The workflow is **generated** by `scripts/alfred-dot-workflow.py`. A workflow
`info.plist` edited through Alfred's UI is an unreviewable blob that drifts
from the CLI; these Script Filters call `dot commands --json`, so they list
whatever exists.

```bash
dot alfred workflow    # regenerate; Alfred indexes it on relaunch
```

Two mechanics to preserve:

- The terminal action hands Ghostty `bin/dot-in-terminal` as a program to
  **exec**, with the subcommand as plain argv. It must not use
  `--initial-command="shell:…"`, which Ghostty wraps as
  `login -flp <user> /bin/bash --noprofile --norc -c exec -l <string>` — that
  prepended `exec -l` replaces the shell with the first command, so a trailing
  `; exec /bin/zsh -l` never runs and the window closes immediately.
- Each launch opens a **new Ghostty instance**, since `open` discards `--args`
  without `-n`. `dot menu` is the in-place alternative.

### Workflows

`alfred/workflows.txt` is a **union across machines**, not this machine's
inventory: an entry is never dropped because it is not installed here, which
is what `alfred.sh install` needs it to mean.

```bash
dot alfred save        # record installed workflows into the union
dot alfred install     # install everything listed that is missing here
dot alfred sync        # both
```

`install` downloads and **unzips** into the workflows directory — a
`.alfredworkflow` is a ZIP, and Alfred loads plain directories. Alfred's import
sheet needs a click per workflow and refuses several at once, so it is avoided
entirely; the trade-off is that unzipping keeps the author's hotkeys, which the
import sheet would strip.

Two supporting files:

- `alfred/workflows.ignore` — bundleids never to list or install. Necessary
  because a union cannot forget: without it, a workflow removed here is
  re-added by the next machine that still has it. It holds ChatGPT / DALL-E
  and *New Terminal Window*, the latter replaced by the `tw` keyword.
- `alfred/workflows.sources` — per-bundleid download overrides. The source
  column comes from the workflow's own `webaddress` key, which is usually the
  author's homepage rather than a repository.

---

## Layout

```
~/.config/yadm/
  bin/                 dot and its subcommands
  lib/common.sh        logging, run(), confirm()
  scripts/             theme.sh, install.sh, alfred.sh, commit-and-push.sh, …
  doctor.d/            one check per file  (+ *.allow)
  update.d/            one update step per file
  themes/              palettes, meta, templates  (see themes/README.md)
  packages/            Brewfile.<group>
  launchd/             *.plist.template  (@HOME@ is substituted)
  editors/             VS Code settings, keybindings, extension list
  alfred/              preference bundle, workflows.txt/.ignore/.sources
  hooks/pre_commit     refuses to commit credentials
  MANUAL.md            this file
```

Generated and gitignored: `.config/zsh/.zshrc`, `.config/yadm/bootstrap`, every
colour file, `~/.local/bin/dot`, the rendered LaunchAgents.

---

## Recovery

```bash
dot doctor                      # start here
dot doctor --fix                # if it offers something
dot converge                    # config pulled but not applied
dot theme render                # colours wrong or missing
yadm status --short             # what is uncommitted
```

Nothing in `~/.ssh`, `~/.gnupg`, `~/.aws` or `~/.npmrc` is in this repository;
the root README lists what must be recreated by hand. The `pre_commit` hook
refuses anything credential-shaped, which matters because the sync commits
unattended to a public repository.
