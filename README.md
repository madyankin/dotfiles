# Dotfiles

Managed with [yadm](https://yadm.io). The work tree is `$HOME`, so everything
below is about being deliberate with what that implies.

This file is tracked at the repository root so GitHub renders it, and excluded
from the work tree by a sparse-checkout rule so it does not sit in `$HOME`.
`bootstrap` sets that rule up on a fresh clone.

## Layout

```
~/.zshenv                     sets ZDOTDIR, PATH, locale — must stay at $HOME
~/.gitconfig  ~/.gitignore    stay at $HOME (relative includeIf resolution)
~/.default-gems  ~/.dip/      required at $HOME by their tools
~/.vimrc                      nvim is the real editor; not worth relocating

~/.config/
  zsh/            .zshrc##template + plugins/options/aliases/functions modules
  agents/         skills/ and agents/ shared by every AI agent
  yadm/
    bootstrap##os.Darwin      per-OS, selected by `yadm alt`
    bootstrap##os.Linux
    crontab                   installed by scripts/cron.sh
    packages/Brewfile.*       one manifest per install group
    scripts/                  install.sh, agents.sh, editors.sh, macos.sh, …
    editors/                  shared Cursor + VS Code settings
  nvim/  tmux/  aerospace/  iterm/  zed/  htop/  mc/  gh/  goose/
```

## Bootstrap on a new machine

0. Copy `~/Parallels` and `~/Projects` to an external drive (`mc` works well).
1. Format the drive and install macOS.
2. Remove everything from the Dock.
3. Install Homebrew from https://brew.sh.
4. `brew install yadm`.
5. Generate an SSH key, save the passphrase to the keychain:
   https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
6. Add it at https://github.com/settings/ssh/new (`cat ~/.ssh/id_ed25519.pub | pbcopy`),
   and remove the old key.
7. `yadm clone git@github.com:madyankin/dotfiles.git`
8. `~/.config/yadm/bootstrap`
9. Recreate the untracked files listed below.
10. Remove everything from Finder's sidebar. Pin the PARA and Family Docs
    directories from Documents.
11. Add the Guitar and Downloads directories to the Dock.
12. Copy `~/Parallels` and `~/Projects` back.
13. Set up Arq backups: Desktop, Documents, Projects, Parallels, Obsidian and
    external drives (skipped when unmounted). Download the supported Arq
    version from the Arq account.

`bootstrap` runs, in order: macOS defaults → software wizard → iTerm2 → editors
→ zsh → cron → agent config links.

## Installing and removing software

`~/.config/yadm/scripts/install.sh` — re-runnable at any time.

Groups: `essentials`, `personal`, `claude`, `codex`, `cursor`, `goose`. Each is
backed by `packages/Brewfile.<group>` (or an npm global). Select a group as a
whole with `<All>`, or expand it to toggle individual packages. The wizard opens
pre-filled from what is actually installed.

`install.sh --dry-run` prints the plan without touching anything.

**Removal is scoped.** A package is uninstalled only when it appears in some
group's manifest *and* is absent from the current selection, evaluated across
all groups at once. Anything this config has never claimed — most of what is on
the machine — is left alone. Every removal is listed and confirmed first.

## Sync

`scripts/commit-and-push.sh` runs every two hours from `crontab`. It pulls,
stages, commits and pushes.

Staging is deliberately two-part, because the work tree is `$HOME`:

- `yadm add -u` — changes to already-tracked files, anywhere.
- `yadm add -A` over `.config/{agents,yadm,nvim,goose/recipes,zsh}` — new files
  too, but only where new dotfiles legitimately appear.

A bare `yadm add -A` would stage `~/Documents`, `~/Downloads` and `~/Projects`.
New dotfiles outside those directories are added by hand.

Run it manually with `sync-dotfiles`.

## Not tracked — recreate by hand

Deliberately absent from the repo. `.gitignore` denies them outright so a
mistaken `add -A` at `$HOME` cannot publish them.

| Path | What to do |
|---|---|
| `~/.ssh/`, `~/.gnupg/`, `~/.aws/`, `~/.netrc` | Regenerate keys; never commit |
| `~/.npmrc` | Holds an npm `_authToken`; re-run `npm login` |
| `~/.config/gh/hosts.yml` | `gh auth login` |
| `~/.config/zsh/local.zsh` | Machine-specific shell config — anything with a path or token |
| `~/.claude/settings.json`, `settings.local.json` | Per-machine plugins and permission grants |
| `~/.zprofile` | Written by OrbStack; `$ZDOTDIR/.zprofile` sources it |
| `~/.gitconfig.personal`, `~/.gitconfig.local` | Per-machine git identity, referenced by `includeIf` |
| `~/.config/yadm/packages/.selection` | Wizard selection state |

## Things that will bite

- **`ZDOTDIR` relocates every zsh startup file**, `.zprofile` included. That is
  why `$ZDOTDIR/.zprofile` exists: it sources `~/.zprofile`, which OrbStack
  rewrites without asking. It also moves `.zsh_history` into `.config/zsh`,
  which the sync script stages — hence the ignore rules.
- **Never source `~/.zshenv` from `.zshrc`.** zsh reads it first; re-sourcing it
  re-prepends `PATH` after `typeset -U path` has deduplicated it.
- **`.gitconfig` must stay at `$HOME`.** Its `includeIf` paths are relative and
  resolve against the including file's own directory, so moving it to
  `.config/git/config` silently re-points them.
- **`GROUPS` is a built-in bash array** of the user's group IDs. Assigning to it
  does nothing.
- **macOS ships bash 3.2** — no associative arrays. `declare -A` degrades to an
  indexed array whose string keys evaluate as arithmetic, so every key collides
  on index 0.
- **`ln -sfn X Y` lands inside `Y`** when `Y` already resolves to a directory.
  `scripts/agents.sh` guards against this; it is what created two
  self-referential symlink loops under `.config/agents/`.
- **Files generated by `yadm alt`** (`.config/yadm/bootstrap`,
  `.config/zsh/.zshrc`) are gitignored. yadm's own `info/exclude` is not enough,
  because the scoped `add -A` overrides it.

## Agent configuration

`~/.config/agents/{skills,agents}` is shared by every agent and linked in by
`scripts/agents.sh` (idempotent, safe to re-run):

```
~/.agents        -> .config/agents          (tracked; goose resolves through it)
~/.claude/skills -> ../.config/agents/skills
~/.claude/agents -> ../.config/agents/agents
… same for ~/.codex, ~/.cursor, ~/.goose
```

`~/.codex/skills` is a real directory holding codex's own `.system/`, so the
linker declines it rather than destroying it.

Skills follow one naming scheme: action skills are `verb-object`, expertise
skills are `domain-topic`, tool wrappers take the tool's name, and families
share a prefix (`explain-*`, `rpi-*`, `obsidian-*`). A skill's `name:`
frontmatter must equal its directory name.

Skills carry no paths, secrets or configuration. The explainers read their vault
layout and deck names from a note inside Obsidian — see
`skills/obsidian-cli/references/vault-resolution.md`.

`~/.config/agents/.skill-lock.json` records skills vendored from upstream repos. Currently
only `find-skills`. Renaming or editing a vendored skill desyncs it from its
lock entry; fork it deliberately instead.

## Editors

Cursor and VS Code share `yadm/editors/{settings.json,keybindings.json}` via
symlink. `scripts/editors.sh sync` reconciles installed extensions against
`editors/extensions.txt`; the sync script runs it every two hours.
