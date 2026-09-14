#!/usr/bin/env bash
#
# Periodic dotfiles sync, driven by cron (see .config/yadm/crontab).
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

# Sync down before staging, so a rebase never lands on a dirty index.
yadm pull --rebase --autostash >/dev/null 2>&1 || exit 1

# Two-part staging. The worktree IS $HOME, so a bare `yadm add -A` would
# sweep in ~/Documents, ~/Downloads, ~/Projects — everything not ignored.
#   -u          : changes to files already tracked, anywhere
#   -A <dirs>   : new files too, but only where new dotfiles legitimately appear
yadm add -u

# git aborts the entire `add` on a pathspec that matches nothing, staging
# NOTHING — so only pass directories that actually exist on this machine.
SCOPED=(
  .config/agents
  .config/yadm
  .config/nvim
  .config/goose/recipes
  .config/zsh
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
