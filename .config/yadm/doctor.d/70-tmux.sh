#!/usr/bin/env bash
# dot:check=tmux can actually start a session
set -uo pipefail

# This exists because tmux was completely unusable for an unknown length of
# time: tmux.conf set default-command to reattach-to-user-namespace, which was
# not installed, so every pane died on spawn and took the server with it. A
# config that parses is not proof that tmux works.
have tmux || { warn "tmux not installed"; exit 0; }

sock="dot-doctor-$$"
if tmux -L "$sock" -f "$HOME/.config/tmux/tmux.conf" new-session -d 2>/dev/null; then
  dead="$(tmux -L "$sock" list-panes -a -F '#{pane_dead}' 2>/dev/null | grep -c 1)"
  tmux -L "$sock" kill-server 2>/dev/null
  if [[ "$dead" == "0" ]]; then
    ok "tmux starts and panes survive"
    exit 0
  fi
  err "tmux starts but panes die immediately — check default-command in tmux.conf"
  exit 1
fi
err "tmux cannot start a session with ~/.config/tmux/tmux.conf"
exit 1
