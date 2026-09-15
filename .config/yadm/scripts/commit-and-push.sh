#!/usr/bin/env bash
#
# Periodic dotfiles sync. Scheduled by scripts/cron.sh: a launchd user agent
# on macOS (.config/yadm/launchd/), the tracked crontab on Linux.
#
# Deliberately NOT `set -e`: `yadm commit` exits 1 on an empty index, which
# used to kill the script before it ever reached `yadm pull`. A machine with
# no local changes then never synced down.
set -uo pipefail

source "$HOME/.zshenv"
cd "$HOME" || exit 1

# Editor extensions first, so anything it rewrites lands in THIS commit
# rather than waiting for the next run two hours later.
"$HOME/.config/yadm/scripts/editors.sh" sync >/dev/null 2>&1 || true

# Keep the Alfred workflow list current, so a workflow added or removed since
# the last run is recorded rather than drifting.
"$HOME/.config/yadm/scripts/alfred.sh" save >/dev/null 2>&1 || true

# Sync down before staging, so a rebase never lands on a dirty index.
yadm pull --rebase --autostash >/dev/null 2>&1 || exit 1

# A pull moves only TRACKED files. Everything generated or linked — the yadm
# alt output (.config/zsh/.zshrc included), the `dot` symlink, every colour
# file — is gitignored because it is an output, so a machine that only ever
# pulls sees none of the changes. Converge is the idempotent subset of
# bootstrap that closes that gap; it writes nothing when already in sync.
if [[ -x "$HOME/.config/yadm/bin/dot-converge" ]]; then
  "$HOME/.config/yadm/bin/dot-converge" --quiet || true
fi

# Two-part staging. The worktree IS $HOME, so a bare `yadm add -A` would
# sweep in ~/Documents, ~/Downloads, ~/Projects — everything not ignored.
#   -u          : changes to files already tracked, anywhere
#   -A <dirs>   : new files too, but only where new dotfiles legitimately appear
# `add -u` stages the DELETION of any tracked file missing on the machine
# running this. Correct for shared config — delete a file on purpose and the
# removal syncs — and destructive for anything that is per-machine.
#
# Alfred's own workflows are per-machine: a workflow absent here means "not
# installed on this machine", not "deleted". Without the exclusion below,
# commit 1e6de0b deleted the tracked App launcher workflow for BOTH machines
# simply because the syncing machine did not have it.
ALFRED_WORKFLOWS='.config/yadm/alfred/Alfred.alfredpreferences/workflows'

yadm add -u -- . ":(exclude)$ALFRED_WORKFLOWS"

# Same directory, additions and modifications only. --ignore-removal is the
# whole point: new and changed workflow files are recorded, missing ones are
# left alone.
if [[ -d "$ALFRED_WORKFLOWS" ]]; then
  yadm add --ignore-removal -- "$ALFRED_WORKFLOWS"
fi

# git aborts the entire `add` on a pathspec that matches nothing, staging
# NOTHING — so only pass directories that actually exist on this machine.
SCOPED=(
  .config/agents
  .config/yadm
  .config/nvim
  .config/goose/recipes
  .config/zsh
  .config/tmux
  .config/ghostty
  .config/bat
  .config/btop
  .config/htop
  .config/mise
)
present=()
for d in "${SCOPED[@]}"; do
  [[ -d "$d" ]] && present+=("$d")
done
(( ${#present[@]} )) && yadm add -A -- "${present[@]}"

# Nothing staged is the normal case; exit clean so cron stays quiet.
yadm diff --cached --quiet && exit 0

yadm commit -q -m "chore(sync): $(date -u +%F' '%T) $(hostname -s)" >/dev/null 2>&1
yadm push >/dev/null 2>&1
