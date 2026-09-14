# Shell functions.
#
# This file is zsh, not bash — unlike everything in .config/yadm/scripts/.

git-clean-branches() {
  git fetch -p
  git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D
}

g++-run() {
  g++ -lstdc++ -std=c++14 -pipe -O2 -Wall "$1" && ./a.out
}

# --- theme-aware TUI wrappers ---
#
# htop and mc both rewrite their own config file when they exit, which is why
# generating that file directly would put the renderer in a permanent fight
# with the app. Both have an environment-variable escape hatch instead, and
# both are foreground tools you start and quit — so reading the appearance once
# per launch is exactly the right granularity. No watcher involved.

# Which mode macOS is in right now. The key is ABSENT in light mode.
_yadm_mode() {
  [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]] && echo dark || echo light
}

# htop has no theme file at all — only color_scheme 0..6 inside htoprc. So
# theme.sh renders one htoprc per mode and HTOPRC selects it. htop's
# write-back on exit then lands in the generated file, never in htoprc.base.
htop() {
  local f="$HOME/.config/htop/htoprc.$(_yadm_mode)"
  if [[ -f "$f" ]]; then
    HTOPRC="$f" command htop "$@"
  else
    command htop "$@"
  fi
}

# mc skins live in ~/.local/share/mc/skins and MC_SKIN overrides the `skin=`
# key in mc's ini (man mc lists it as precedence source 2).
#
# The truecolor skin needs a 256-colour TERM *and* COLORTERM=truecolor|24bit;
# without COLORTERM mc renders the hex skin wrong, so fall back to the
# ANSI-named skin, which follows the terminal palette for free.
mc() {
  local skin
  if [[ -n "$COLORTERM" ]]; then
    skin="yadm-$(_yadm_mode)"
  else
    skin="yadm-ansi"
  fi
  if [[ -f "$HOME/.local/share/mc/skins/$skin.ini" ]]; then
    MC_SKIN="$skin" command mc --nosubshell "$@"
  else
    command mc --nosubshell "$@"
  fi
}
