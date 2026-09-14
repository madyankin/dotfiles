#!/usr/bin/env bash
# dot:step=Mac App Store apps
have mas || { warn "mas not installed"; return 0 2>/dev/null || exit 0; }
# Non-fatal: mas fails when not signed in, and that must not stop the run.
if ! run mas upgrade; then
  warn "mas upgrade failed (not signed in to the App Store?)"
fi
ok "mas done"
