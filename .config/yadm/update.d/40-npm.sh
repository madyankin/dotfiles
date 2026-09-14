#!/usr/bin/env bash
# dot:step=npm globals not owned by mise
MANIFEST="$DOT_ROOT/packages/npm-globals.txt"
if [[ ! -s "$MANIFEST" ]]; then
  note "no npm globals manifested — the agent CLIs are mise npm: tools now"
  return 0 2>/dev/null || exit 0
fi
have npm || { warn "npm not on PATH"; return 0 2>/dev/null || exit 0; }
while IFS= read -r pkg; do
  case "$pkg" in ""|\#*) continue ;; esac
  # Per-package @latest, never a blanket `npm -g update`: under a shimmed node
  # that is how a whole toolchain gets bricked at once.
  run npm install -g "$pkg@latest"
done < "$MANIFEST"
ok "npm globals done"
