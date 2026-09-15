# Shared helpers for bin/dot* and the *.d step scripts.
#
# House style is install.sh's: ━━━ headers, → for actions, ✓ ! ✗ for outcomes.
# Deliberately no `gum`: install.sh is already a coherent bash 3.2 TUI, and two
# prompt idioms in one repo is worse than one plainer one.
#
# bash 3.2 — no associative arrays, no ${arr[-1]}, no mapfile, no ${var^^}.
#
# KNOWN LIMIT: run() takes an argv, so it cannot express a pipeline. A step
# that needs one must guard DOT_DRY_RUN itself.

DOT_ROOT="${DOT_ROOT:-$HOME/.config/yadm}"
DOT_STATE="${DOT_STATE:-$HOME/.local/state/dot}"
DOT_DRY_RUN="${DOT_DRY_RUN:-}"

header() { echo ""; echo "━━━ $1 ━━━"; }
log()    { printf '→ %s\n' "$*"; }
ok()     { printf '  ✓ %s\n' "$*"; }
warn()   { printf '  ! %s\n' "$*"; }
err()    { printf '  ✗ %s\n' "$*" >&2; }
note()   { printf '    %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# run <cmd> [args...] — echo instead of executing under DOT_DRY_RUN=1.
run() {
  if [[ -n "$DOT_DRY_RUN" ]]; then
    printf '  would run: %s\n' "$*"
    return 0
  fi
  "$@"
}

confirm() {  # confirm "question" -> 0 on yes
  [[ -n "${DOT_YES:-}" ]] && return 0
  local reply
  printf '  %s [y/N] ' "$1"
  read -r reply
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

state_dir() { mkdir -p "$DOT_STATE"; printf '%s' "$DOT_STATE"; }

# --------------------------------------------------------------- pickers ---
#
# fzf is already a dependency and already backs `dot menu`, so every prompt
# that asks "which one?" uses it rather than making you type an exact name or
# count rows in a printf table. Candidates arrive on stdin.
#
# Each falls back to a plain read when fzf is missing, so nothing here is
# unusable over a bare ssh session.

# Is an interactive TUI possible at all? fzf draws on /dev/tty, and with no
# controlling terminal it does not fail fast — it HANGS, which turns any
# non-interactive caller (a script, a launchd job, a piped command) into a
# stuck process. So this is checked before fzf is ever invoked.
_tui_ok() {
  have fzf || return 1
  [[ -e /dev/tty ]] || return 1
  ( exec 3<>/dev/tty ) 2>/dev/null || return 1
  return 0
}

pick_one() {  # pick_one <prompt> [preview-command-using-{}]  < candidates
  local prompt="$1" preview="${2:-}"
  if ! _tui_ok; then
    local all reply
    all="$(cat)"
    if [[ ! -t 0 ]]; then
      printf '%s\n' "$all" | sed 's/^/  /' >&2
      printf '  (no terminal — nothing selected)\n' >&2
      return 0
    fi
    printf '%s\n' "$all" | sed 's/^/  /' >&2
    printf '  %s: ' "$prompt" >&2
    read -r reply
    printf '%s' "$reply"
    return 0
  fi
  if [[ -n "$preview" ]]; then
    fzf --height=70% --layout=reverse --border --prompt="$prompt > " \
        --preview="$preview" --preview-window='right,55%,border-left' \
        --bind='ctrl-/:toggle-preview'
  else
    fzf --height=40% --layout=reverse --border --prompt="$prompt > "
  fi
}

pick_many() {  # pick_many <prompt> [preview]  < candidates   -> one per line
  local prompt="$1" preview="${2:-}"
  if ! _tui_ok; then
    local all reply
    all="$(cat)"
    # No terminal means no prompting either: a non-interactive caller must get
    # an empty selection rather than a blocked read.
    if [[ ! -t 0 ]]; then
      printf '%s\n' "$all" | sed 's/^/  /' >&2
      printf '  (no terminal — nothing selected)\n' >&2
      return 0
    fi
    printf '%s\n' "$all" | sed 's/^/  /' >&2
    printf '  %s (space-separated): ' "$prompt" >&2
    read -r reply
    printf '%s\n' $reply
    return 0
  fi
  if [[ -n "$preview" ]]; then
    fzf --multi --height=70% --layout=reverse --border --prompt="$prompt > " \
        --header=$'tab select · enter confirm\n' \
        --preview="$preview" --preview-window='right,55%,border-left'
  else
    fzf --multi --height=50% --layout=reverse --border --prompt="$prompt > " \
        --header=$'tab select · enter confirm\n'
  fi
}
