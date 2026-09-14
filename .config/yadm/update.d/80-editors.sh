#!/usr/bin/env bash
# dot:step=VS Code extension reconcile
[[ -x "$DOT_ROOT/scripts/editors.sh" ]] || { warn "editors.sh missing"; return 0 2>/dev/null || exit 0; }
run "$DOT_ROOT/scripts/editors.sh" sync
ok "editors done"
