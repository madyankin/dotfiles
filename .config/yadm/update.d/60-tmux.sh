#!/usr/bin/env bash
# dot:step=tmux plugins via tpm
TPM="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM" ]]; then
  warn "tpm not installed at ~/.tmux/plugins/tpm"
  return 0 2>/dev/null || exit 0
fi
run "$TPM/bin/install_plugins"
run "$TPM/bin/update_plugins" all
ok "tmux plugins done"
