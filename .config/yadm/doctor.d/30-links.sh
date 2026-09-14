#!/usr/bin/env bash
# dot:check=every symlink the setup scripts create still points somewhere
set -uo pipefail
rc=0

check_link() {  # path
  local p="$1" t
  if [[ -L "$p" ]]; then
    t="$(readlink "$p")"
    if [[ -e "$p" ]]; then
      ok "link ok: ${p/#$HOME/~}"
    else
      err "broken link: ${p/#$HOME/~} -> $t"; rc=1
    fi
  elif [[ -e "$p" ]]; then
    warn "exists but is not a symlink: ${p/#$HOME/~}"
  else
    err "missing: ${p/#$HOME/~}"; rc=1
  fi
}

check_link "$HOME/.local/bin/dot"
check_link "$HOME/.agents"
check_link "$HOME/.claude/skills"
check_link "$HOME/.claude/agents"
check_link "$HOME/Library/Application Support/Code/User/settings.json"
check_link "$HOME/Library/Application Support/Code/User/keybindings.json"

# yadm alt output must exist, or the shell has no interactive config at all.
for f in "$HOME/.config/zsh/.zshrc" "$HOME/.config/yadm/bootstrap"; do
  if [[ -e "$f" ]]; then ok "yadm alt output present: ${f/#$HOME/~}"
  else err "missing yadm alt output: ${f/#$HOME/~} — run: yadm alt"; rc=1; fi
done

# The ZDOTDIR shim: without it, nested zsh reads $ZDOTDIR/.zshenv (absent) and
# silently keeps whatever PATH it inherited.
if [[ -f "$HOME/.config/zsh/.zshenv" ]]; then
  ok "\$ZDOTDIR/.zshenv shim present"
else
  err "no \$ZDOTDIR/.zshenv — nested zsh will skip ~/.zshenv entirely"; rc=1
fi

exit $rc
