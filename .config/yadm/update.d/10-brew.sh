#!/usr/bin/env bash
# dot:step=Homebrew formulae and casks
have brew || { warn "brew not installed"; return 0 2>/dev/null || exit 0; }

run brew update
run brew upgrade

# NOT --greedy. It force-updates casks that ship their own updaters
# (1Password, Chrome, Zed, Obsidian), which fights them and occasionally
# downgrades a self-updated app back to the cask's pinned version.
run brew upgrade --cask

if [[ -n "${DOT_PRUNE:-}" ]]; then
  run brew cleanup
else
  note "old versions kept; pass --prune to run brew cleanup"
fi
ok "brew done"
