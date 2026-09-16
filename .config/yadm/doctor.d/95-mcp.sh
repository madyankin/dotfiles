#!/usr/bin/env bash
# dot:check=MCP servers Claude Code launches can still start
#
# Every failure this checks for has already happened once. An MCP whose command
# or interpreter has gone missing does not announce itself: the client reports
# "Connection closed" or caches the failure for 15 minutes, and the tools are
# simply absent from the session. Removing asdf (see the runtimes check) took
# the Apple Mail plugin's venv interpreter with it exactly this way.
set -uo pipefail
rc=0
shopt -s nullglob

MCP_JSON="$HOME/Code/.mcp.json"
PLUGIN_CACHE="$HOME/.claude/plugins/cache"

# --- 1. every command named in the synced .mcp.json resolves -----------------

if [[ ! -f "$MCP_JSON" ]]; then
  warn "no ${MCP_JSON/#$HOME/~} — the Drive setup.sh has not linked it here"
elif ! /usr/bin/python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$MCP_JSON" 2>/dev/null; then
  err "${MCP_JSON/#$HOME/~} is not valid JSON — every server in it is dead"; rc=1
else
  while IFS=$'\t' read -r name cmd; do
    [[ -n "$name" ]] || continue
    case "$cmd" in
      /*) if [[ -x "$cmd" ]]; then ok "mcp $name: $cmd"
          else err "mcp $name: not executable: $cmd"; rc=1; fi ;;
      *)  if resolved="$(command -v "$cmd" 2>/dev/null)"; then ok "mcp $name: $cmd -> $resolved"
          else err "mcp $name: command not on PATH: $cmd"; rc=1; fi ;;
    esac
  done < <(/usr/bin/python3 - "$MCP_JSON" <<'PY'
import json, sys
for name, spec in json.load(open(sys.argv[1])).get("mcpServers", {}).items():
    cmd = spec.get("command")
    if cmd:
        print("%s\t%s" % (name, cmd))
PY
  )
fi

# --- 2. plugin venv interpreters RUN, not merely exist ----------------------
#
# -f is not enough. A venv whose python3 symlink points at a deleted runtime
# passes every existence test and then exits 127 on launch.

venvs=0
for py in "$PLUGIN_CACHE"/*/*/*/venv/bin/python3; do
  venvs=$((venvs+1))
  plugin="${py#"$PLUGIN_CACHE"/}"; plugin="${plugin%%/*}"
  if ver="$("$py" -V 2>&1)"; then
    ok "plugin venv $plugin: $ver"
  else
    err "plugin venv $plugin: interpreter does not run — ${py/#$HOME/~}"
    err "  rebuild: rm -rf \"\$(dirname \"\$(dirname \"$py\")\")\" && uv venv --python 3.12 …"
    rc=1
  fi
done
[[ $venvs -gt 0 ]] || warn "no plugin venvs found — a plugin that builds one on first connect will exceed the 30s window and be cached as a failure"

# --- 3. nothing points into a version manager we removed --------------------

for py in "$PLUGIN_CACHE"/*/*/*/venv/bin/python3; do
  target="$(readlink "$py" 2>/dev/null)" || continue
  case "$target" in
    *.asdf*) err "venv interpreter points into removed asdf: ${py/#$HOME/~} -> $target"; rc=1 ;;
  esac
done
if [[ -f "$MCP_JSON" ]] && grep -q '\.asdf' "$MCP_JSON"; then
  err "${MCP_JSON/#$HOME/~} references .asdf — asdf is gone, mise owns runtimes"; rc=1
fi

exit $rc
