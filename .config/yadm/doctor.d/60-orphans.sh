#!/usr/bin/env bash
# dot:check=tracked config for apps that are not installed here
set -uo pipefail

# REPORT ONLY, never fix, and never fail the run. This is a two-machine repo:
# a config with no app on THIS machine is perfectly normal if the app lives on
# the other one. The same reasoning is why there is no check for unresolved
# `includeIf` paths in .gitconfig — ~/.gitconfig.personal is intentionally
# absent here.
#
# Suppress a known-good entry by listing it in .config/yadm/doctor.d/orphans.allow
ALLOW="$DOT_ROOT/doctor.d/orphans.allow"

pairs="
aerospace:aerospace
karabiner:karabiner_cli
btop:btop
htop:htop
mc:mc
ghostty:ghostty
zed:zed
tmux:tmux
nvim:nvim
gh:gh
goose:goose
mise:mise
"
found=0
while IFS=: read -r dir bin; do
  [[ -z "$dir" ]] && continue
  [[ -d "$HOME/.config/$dir" ]] || continue
  grep -qx -- "$dir" "$ALLOW" 2>/dev/null && continue
  if ! command -v "$bin" >/dev/null 2>&1 \
     && [[ ! -d "/Applications/${bin}.app" ]] \
     && ! ls -d /Applications/*.app 2>/dev/null | grep -qi "/${bin}"; then
    warn "~/.config/$dir exists but '$bin' is not installed here"
    found=$((found+1))
  fi
done <<<"$pairs"

if [[ $found -eq 0 ]]; then
  ok "no orphaned config directories"
else
  note "if that is deliberate, add the directory name to doctor.d/orphans.allow"
fi
exit 0
