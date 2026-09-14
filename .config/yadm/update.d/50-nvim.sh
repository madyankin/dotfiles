#!/usr/bin/env bash
# dot:step=Neovim plugins (rewrites the tracked lazy-lock.json)
have nvim || { warn "nvim not installed"; return 0 2>/dev/null || exit 0; }
# The lockfile is TRACKED on purpose: the next sync commits the new pins and
# the other machine gets the same plugin versions.
run nvim --headless "+Lazy! sync" +qa
ok "nvim plugins synced (lazy-lock.json may have changed)"
