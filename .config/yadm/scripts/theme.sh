#!/usr/bin/env bash
#
# Theme engine. One palette per theme+mode generates every app's colours.
#
# The engine renders BOTH modes for every target and lets each app's own
# light/dark detection pick one. That is why there is no appearance daemon here:
# Ghostty, nvim, VS Code, Zed and iTerm2 all switch themselves, and tmux, fzf,
# p10k and ls are rendered in ANSI index space so the terminal's palette swap
# repaints them in already-running shells.
#
# The single exception is Terminal.app, which has no light/dark awareness at
# all. `theme.sh watch` exists for it and nothing else, and it is opt-in.
#
# macOS ships bash 3.2 — no associative arrays, no `declare -A`. Keep it 3.2-safe.
set -uo pipefail

YADM_DIR="$HOME/.config/yadm"
THEMES_DIR="$YADM_DIR/themes"
SCRIPTS_DIR="$YADM_DIR/scripts"
RENDERER="$SCRIPTS_DIR/theme_render.py"
ACTIVE="$THEMES_DIR/.active"          # untracked, per-machine, like packages/.selection
BACKGROUND_STATE="$THEMES_DIR/.background"
LOCKDIR="${TMPDIR:-/tmp}/yadm-theme.lock"
LABEL="name.madyankin.theme.watch"

# flock(1) does not exist on macOS (util-linux only). mkdir is atomic.
PY=/usr/bin/python3

log()  { printf '→ %s\n' "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
err()  { printf '  ✗ %s\n' "$*" >&2; }

require_py() {
  if [[ ! -x "$PY" ]]; then
    err "$PY not found. It is the CommandLineTools python3; install Xcode or the CLT."
    exit 1
  fi
  if ! "$PY" -c 'import plistlib, json' 2>/dev/null; then
    err "$PY cannot import plistlib/json"
    exit 1
  fi
}

lock() {
  local tries=0
  until mkdir "$LOCKDIR" 2>/dev/null; do
    tries=$((tries+1))
    if [[ $tries -gt 50 ]]; then
      err "another theme operation is holding $LOCKDIR"
      exit 1
    fi
    sleep 0.1
  done
  trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT INT TERM
}

current_theme() {
  if [[ -f "$ACTIVE" ]]; then
    cat "$ACTIVE"
  else
    echo github
  fi
}

current_mode() {
  if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
    echo dark
  else
    echo light
  fi
}

list_themes() {
  local d
  for d in "$THEMES_DIR"/*/; do
    [[ -f "$d/palette.light.sh" ]] || continue
    basename "$d"
  done
}

meta_get() {  # theme key
  local f="$THEMES_DIR/$1/meta.sh" k="$2" v
  [[ -f "$f" ]] || return 1
  v="$(grep "^$k=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)"
  v="${v%\"}"; v="${v#\"}"
  printf '%s' "$v"
}

# ------------------------------------------------------------------ reloads --

reload_tmux() {
  command -v tmux >/dev/null || return 0
  tmux list-sessions >/dev/null 2>&1 || return 0
  tmux source-file "$HOME/.config/tmux/theme.conf" 2>/dev/null \
    && ok "tmux sessions re-sourced"
}

reload_terminal_app() {
  # Terminal.app is the one target that must be pushed. Import both profiles,
  # then point the default at the one matching the current appearance.
  local theme="$1" mode f name stamp imported=0
  mode="$(current_mode)"
  stamp="$THEMES_DIR/.terminal-imported"
  for f in "$THEMES_DIR/$theme/generated"/yadm-*.terminal; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f" .terminal)"
    # Import only when the profile is absent or the generated file is newer
    # than the last import; `open` launches Terminal.app, so do not do it on
    # every render.
    if ! defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q "\"$name\"" \
       || [[ ! -f "$stamp" || "$f" -nt "$stamp" ]]; then
      open -g "$f" 2>/dev/null || true
      imported=1
    fi
  done
  if [[ $imported -eq 1 ]]; then
    sleep 1                      # `open` is async; the domain lags behind it
    touch "$stamp"
  fi
  defaults write com.apple.Terminal "Default Window Settings" -string "yadm-$mode"
  defaults write com.apple.Terminal "Startup Window Settings" -string "yadm-$mode"
  ok "Terminal.app default profile: yadm-$mode (applies to NEW windows only)"
}

reload_notes() {
  cat <<'EOT'
  ! Two apps need a nudge that no script can give them:
      Ghostty  — Cmd+Shift+, reloads its config (theme file contents changed)
      Neovim   — :source $MYVIMRC, or just reopen it
EOT
}

# ------------------------------------------------------------- subcommands --

cmd_list() {
  local cur t
  cur="$(current_theme)"
  for t in $(list_themes); do
    if [[ "$t" == "$cur" ]]; then printf '* %s\n' "$t"; else printf '  %s\n' "$t"; fi
  done
}

cmd_current() { current_theme; }

cmd_render() {
  local theme args=()
  theme="$(current_theme)"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip) args+=(--skip "$2"); shift 2 ;;
      --only) args+=(--only "$2"); shift 2 ;;
      --no-reload) NO_RELOAD=1; shift ;;
      --theme) theme="$2"; shift 2 ;;
      *) err "unknown option: $1"; exit 2 ;;
    esac
  done
  require_py
  lock
  log "Rendering theme '$theme'"
  "$PY" "$RENDERER" "$theme" "${args[@]+"${args[@]}"}" || exit 1

  if [[ -z "${NO_RELOAD:-}" ]]; then
    reload_tmux
    reload_terminal_app "$theme"
    reload_notes
  fi
}

cmd_set() {
  local theme="${1:-}"
  if [[ -z "$theme" ]]; then err "usage: theme.sh set <name>"; exit 2; fi
  if [[ ! -d "$THEMES_DIR/$theme" ]]; then
    err "no such theme: $theme"
    echo "  available:"; list_themes | sed 's/^/    /'
    exit 1
  fi
  mkdir -p "$THEMES_DIR"
  printf '%s\n' "$theme" > "$ACTIVE"
  shift
  cmd_render --theme "$theme" "$@"
  # Omarchy's theme-set hook, same contract: theme name as $1.
  local h
  for h in "$YADM_DIR/hooks/theme-set.d"/*; do
    [[ -x "$h" ]] || continue
    log "hook $(basename "$h")"
    "$h" "$theme" || warn "hook $(basename "$h") exited $?"
  done
}

cmd_background() {
  local theme dir arg="${1:-next}" files cur idx=0 next
  theme="$(current_theme)"
  dir="$THEMES_DIR/$theme/backgrounds"
  if [[ ! -d "$dir" ]]; then
    warn "no backgrounds for theme '$theme' ($dir)"
    return 0
  fi
  if [[ "$arg" != "next" ]]; then
    set_wallpaper "$arg"; return
  fi
  files=()
  local f
  for f in "$dir"/*; do [[ -f "$f" ]] && files+=("$f"); done
  if [[ ${#files[@]} -eq 0 ]]; then warn "no image files in $dir"; return 0; fi
  cur="$(cat "$BACKGROUND_STATE" 2>/dev/null)"
  local i
  for i in $(seq 0 $((${#files[@]} - 1))); do
    [[ "${files[$i]}" == "$cur" ]] && idx=$(( (i + 1) % ${#files[@]} ))
  done
  next="${files[$idx]}"
  set_wallpaper "$next"
}

set_wallpaper() {
  local img="$1"
  [[ -f "$img" ]] || { err "not a file: $img"; return 1; }
  # No dependency route. It can silently no-op on some multi-display / Stage
  # Manager setups; `desktoppr` is the reliable fallback if that bites.
  if osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$img\"" 2>/dev/null; then
    printf '%s\n' "$img" > "$BACKGROUND_STATE"
    ok "background: $(basename "$img")"
  else
    warn "osascript could not set the wallpaper (Automation permission, or a"
    warn "display layout it cannot address). Install the desktoppr cask if this persists."
    return 1
  fi
}

cmd_capture_htop() {
  # htop rewrites whatever $HTOPRC points at on exit, so a layout change lands
  # in the generated file. This promotes it back into the tracked base.
  local mode src base
  mode="$(current_mode)"
  src="$HOME/.config/htop/htoprc.$mode"
  base="$HOME/.config/htop/htoprc.base"
  [[ -f "$src" ]] || { err "no $src — run render first"; exit 1; }
  {
    sed -n '1,7p' "$base" 2>/dev/null
    grep -v '^color_scheme=' "$src"
  } > "$base.new" && mv "$base.new" "$base"
  ok "promoted htoprc.$mode into htoprc.base"
}

cmd_doctor() {
  local theme rc=0 want got
  theme="$(current_theme)"
  log "theme: $theme   mode now: $(current_mode)"

  # bat: the pair named in meta.sh must exist in bat's theme list
  if command -v bat >/dev/null; then
    local themes; themes="$(bat --list-themes 2>/dev/null)"
    for want in "$(meta_get "$theme" BAT_LIGHT)" "$(meta_get "$theme" BAT_DARK)"; do
      if grep -qx -- "$want" <<<"$themes"; then ok "bat theme present: $want"
      else err "bat theme missing: $want"; rc=1; fi
    done
    if [[ -n "${BAT_THEME:-}" ]]; then
      err "BAT_THEME is set ($BAT_THEME) — it also pins git-delta's syntax-theme"; rc=1
    else
      ok "BAT_THEME unset (delta free to auto-detect)"
    fi
  fi

  # delta must not have a pinned syntax-theme.
  #
  # Check git config, NOT `delta --show-config`: that reports the EFFECTIVE
  # theme, and with nothing configured it resolves to delta's built-in dark
  # default (Monokai Extended) — which looks pinned but is exactly the
  # auto-detecting behaviour we want.
  if command -v delta >/dev/null; then
    got="$(git config --get delta.syntax-theme 2>/dev/null)"
    if [[ -n "$got" ]]; then
      err "delta.syntax-theme is set in git config ($got) — it overrides light/dark detection"; rc=1
    else
      ok "delta.syntax-theme unset in git config (auto light/dark)"
    fi
    if [[ "$(git config --get delta.detect-dark-light 2>/dev/null)" == "auto" ]]; then
      ok "delta detect-dark-light = auto"
    else
      warn "delta detect-dark-light not set to auto (it is the default, so this is cosmetic)"
    fi
  fi

  # p10k overrides must all be ANSI 0-15, or the prompt cannot follow a flip
  local f="$HOME/.config/zsh/p10k-colors.zsh"
  if [[ -f "$f" ]]; then
    local bad; bad="$(grep -oE '=[0-9]+$' "$f" | tr -d '=' | awk '$1>15' | wc -l | tr -d ' ')"
    if [[ "$bad" == "0" ]]; then ok "p10k colours all in ANSI 0-15"
    else err "$bad p10k value(s) outside ANSI 0-15 — those ignore the palette"; rc=1; fi
  else
    warn "p10k-colors.zsh not rendered yet"
  fi

  # generated outputs present
  local p
  for p in \
    "$HOME/.config/ghostty/themes/yadm-light" \
    "$HOME/.config/ghostty/themes/yadm-dark" \
    "$HOME/.config/tmux/theme.conf" \
    "$HOME/.local/share/mc/skins/yadm-light.ini" \
    "$HOME/.config/htop/htoprc.light" \
    "$HOME/Library/Application Support/iTerm2/DynamicProfiles/yadm-theme.json"
  do
    local shown; shown="$(printf '%s' "$p" | sed "s|^$HOME|~|")"
    if [[ -f "$p" ]]; then ok "rendered: $shown"
    else err "missing: $shown"; rc=1; fi
  done

  # mc truecolor prerequisites
  if [[ -n "${COLORTERM:-}" ]]; then ok "COLORTERM=$COLORTERM (mc truecolor skin usable)"
  else warn "COLORTERM unset — mc falls back to the ANSI skin"; fi

  # the watcher is only needed if Terminal.app is in use
  if launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1; then
    ok "Terminal.app appearance watcher loaded"
  else
    warn "Terminal.app watcher not loaded (only needed if you use Terminal.app)"
  fi

  return $rc
}

# ------------------------------------------------------------------- watcher --

cmd_watch() {
  # Terminal.app only. Everything else follows the OS by itself.
  local last="" now
  while :; do
    now="$(current_mode)"
    if [[ "$now" != "$last" ]]; then
      last="$now"
      reload_terminal_app "$(current_theme)" >/dev/null 2>&1
      local h
      for h in "$YADM_DIR/hooks/theme-set.d"/*; do
        [[ -x "$h" ]] && "$h" "$(current_theme)" >/dev/null 2>&1
      done
    fi
    sleep 2
  done
}

cmd_install_agent() {
  local tpl="$YADM_DIR/launchd/$LABEL.plist.template"
  local agent="$HOME/Library/LaunchAgents/$LABEL.plist"
  [[ -f "$tpl" ]] || { err "missing $tpl"; exit 1; }
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.local/state/dot"
  sed "s|@HOME@|$HOME|g" "$tpl" > "$agent"
  plutil -lint "$agent" >/dev/null || { err "rendered plist malformed"; exit 1; }
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$agent"
  ok "loaded $LABEL"
}

cmd_uninstall_agent() {
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
  ok "removed $LABEL"
}

usage() {
  cat <<'EOT'
theme.sh <command>

  list                    themes available (* = active)
  current                 active theme name
  render [opts]           regenerate every target from the active theme
  set <name> [opts]       switch theme, render, run hooks
  background [next|FILE]  cycle or set this theme's wallpaper
  capture-htop            promote the live htop layout back into htoprc.base
  doctor                  report drift between the palette and what apps use
  watch                   foreground appearance watcher (Terminal.app only)
  install-agent           run `watch` as a launchd user agent
  uninstall-agent         remove it

render/set options:
  --skip <group>   terminal | shell | tui | editors | launcher | native
  --only <group>   render just that group
  --no-reload      generate files, tell no app about it

  --skip editors keeps the hand-tuned nvim/VS Code/Zed themes instead of the
  flatter generated ones.
EOT
}

case "${1:-usage}" in
  list)             shift; cmd_list "$@" ;;
  current)          shift; cmd_current "$@" ;;
  render)           shift; cmd_render "$@" ;;
  set)              shift; cmd_set "$@" ;;
  background)       shift; cmd_background "$@" ;;
  capture-htop)     shift; cmd_capture_htop "$@" ;;
  doctor)           shift; cmd_doctor "$@" ;;
  watch)            shift; cmd_watch "$@" ;;
  install-agent)    shift; cmd_install_agent "$@" ;;
  uninstall-agent)  shift; cmd_uninstall_agent "$@" ;;
  -h|--help|usage)  usage ;;
  *) err "unknown command: $1"; usage; exit 2 ;;
esac
