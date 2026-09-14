#!/usr/bin/env bash
# dot:check=shell startup cost and the PATH/hook wiring
set -uo pipefail
rc=0

# PATH order. ~/.local/bin must outrank Homebrew (it holds `dot`), and ./bin
# must NOT be present — it put the bin/ of whatever repo you were standing in
# ahead of your own scripts.
p="$(zsh -i -c 'print -l $path' 2>/dev/null)"
if grep -qx -- '\./bin' <<<"$p"; then
  err "./bin is on PATH — any repo you cd into can shadow your commands"; rc=1
else
  ok "./bin not on PATH"
fi
lb="$(grep -n "^$HOME/.local/bin$" <<<"$p" | cut -d: -f1)"
hb="$(grep -n '^/opt/homebrew/bin$' <<<"$p" | cut -d: -f1)"
if [[ -n "$lb" && -n "$hb" && "$lb" -lt "$hb" ]]; then
  ok "~/.local/bin ($lb) outranks /opt/homebrew/bin ($hb)"
elif [[ -n "$lb" && -n "$hb" ]]; then
  err "~/.local/bin ($lb) is BEHIND /opt/homebrew/bin ($hb)"; rc=1
fi
if grep -q 'asdf' <<<"$p"; then
  warn "an asdf path is still on PATH"
fi

# Stale entries: dirs that no longer exist. ~/.zshenv prunes these, so any hit
# means a shell was started before the prune was added.
stale=0
while IFS= read -r d; do
  [[ -z "$d" ]] && continue
  [[ -d "$d" ]] || stale=$((stale+1))
done <<<"$p"
[[ $stale -eq 0 ]] && ok "no non-existent PATH entries" || warn "$stale PATH entries do not exist"

# direnv must be hooked, or per-project env silently does nothing.
if have direnv; then
  if zsh -i -c 'typeset -f _direnv_hook >/dev/null' 2>/dev/null; then
    ok "direnv hooked into zsh"
  else
    err "direnv installed but never hooked"; rc=1
  fi
fi

# compinit guard: an unguarded compinit re-scans every fpath dir every shell.
if grep -q 'compinit -C' "$HOME/.config/zsh/plugins.zsh" 2>/dev/null; then
  ok "compinit is cache-guarded"
else
  warn "compinit runs unguarded on every shell"
fi

# Startup time. A regression here is usually a new eager `eval "$(...)"`.
t="$( { /usr/bin/time -p zsh -i -c exit ; } 2>&1 | awk '/^real/{print $2}')"
if [[ -n "$t" ]]; then
  if awk "BEGIN{exit !($t > 1.0)}"; then
    warn "interactive zsh startup ${t}s (over the 1.0s threshold)"
  else
    ok "interactive zsh startup ${t}s"
  fi
fi

exit $rc
