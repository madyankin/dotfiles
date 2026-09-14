#!/usr/bin/env bash
# dot:step=Alfred workflow reconcile
[[ -x "$DOT_ROOT/scripts/alfred.sh" ]] || { warn "alfred.sh missing"; return 0 2>/dev/null || exit 0; }
run "$DOT_ROOT/scripts/alfred.sh" sync
ok "alfred done"
