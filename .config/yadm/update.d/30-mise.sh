#!/usr/bin/env bash
# dot:step=mise runtimes and npm-backend CLIs
have mise || { warn "mise not installed"; return 0 2>/dev/null || exit 0; }

# install first: fills in anything config.toml names but is absent.
run mise install
# then upgrade within the pinned ranges.
run mise upgrade
# NEVER mise self-update: mise is Homebrew-managed here, and self-update would
# leave brew's copy and the running binary disagreeing.
ok "mise done"
