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
