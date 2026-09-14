#!/usr/bin/env bash
# dot:step=re-render the theme (templates may have changed in the pull)
[[ -x "$DOT_ROOT/scripts/theme.sh" ]] || { warn "theme.sh missing"; return 0 2>/dev/null || exit 0; }
run "$DOT_ROOT/scripts/theme.sh" render --no-reload
ok "theme re-rendered"
