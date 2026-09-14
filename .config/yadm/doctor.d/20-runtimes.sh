#!/usr/bin/env bash
# dot:check=exactly one version manager, and runtimes resolve non-interactively
set -uo pipefail
rc=0

# The important word is NON-INTERACTIVE. An interactive shell runs `mise
# activate` and hides the breakage; launchd jobs, cron and scripts do not.
out="$(env -i HOME="$HOME" /bin/zsh -c 'python3 -V' 2>&1)"
case "$out" in
  Python*) ok "non-interactive python3: $out" ;;
  *)       err "non-interactive python3 fails: $out"; rc=1 ;;
esac
out="$(env -i HOME="$HOME" /bin/zsh -c 'node -v' 2>&1)"
case "$out" in
  v*) ok "non-interactive node: $out" ;;
  *)  err "non-interactive node fails: $out"; rc=1 ;;
esac
out="$(env -i HOME="$HOME" /bin/zsh -c 'ruby -v' 2>&1)"
case "$out" in
  ruby*) ok "non-interactive ruby: ${out%% *} ${out#* }" ;;
  *)     err "non-interactive ruby fails: $out"; rc=1 ;;
esac

n=0
have mise && n=$((n+1))
have asdf && n=$((n+1))
case $n in
  1) ok "exactly one version manager on PATH" ;;
  0) warn "no version manager on PATH" ;;
  *) err "both mise and asdf are on PATH — their shims will fight"
     note "fix: brew uninstall asdf && mv ~/.asdf ~/.asdf.removed"
     rc=1 ;;
esac

if have mise; then
  if [[ -f "$HOME/.config/mise/config.toml" ]]; then
    ok "mise config.toml tracked"
  else
    err "no ~/.config/mise/config.toml — runtime pins will not reach other machines"; rc=1
  fi
  if [[ -f "$HOME/.tool-versions" ]]; then
    warn "~/.tool-versions exists and shadows the global mise config for paths under \$HOME"
  fi
  if mise ls 2>/dev/null | grep -q '(missing)'; then
    warn "some mise tools report (missing) — run: mise install"
    mise ls 2>/dev/null | grep '(missing)' | sed 's/^/    /'
  else
    ok "no mise tools missing"
  fi
fi

exit $rc
