#!/usr/bin/env bash
#
# Links the shared agent config into each installed agent's directory.
#
# Installing and removing the agents themselves is the install wizard's job
# (install.sh, groups: claude, codex, goose). This script only wires up
# the configuration, and is safe to re-run at any time.
set -uo pipefail

AGENTS_DIR="$HOME/.config/agents"

# Create one symlink idempotently.
#
# Targets stay RELATIVE on purpose: ~/.agents is itself tracked in this repo,
# so an absolute target would commit this machine's username and break the
# checkout on any other machine.
#
# The real defect behind .config/agents/agents/agents and
# .config/agents/skills/skills was the missing guard below, not relativeness:
# `ln -sfn` against a name that already resolves to a directory drops the new
# link *inside* that directory. Refusing any non-symlink target closes that.
link() {  # link <target-relative-to-linkname-dir> <linkname>
  local target="$1" name="$2"

  if [[ -L "$name" ]]; then
    [[ "$(readlink "$name")" == "$target" ]] && return 0   # already correct
    rm -f "$name"
  elif [[ -e "$name" ]]; then
    echo "  ! $name exists and is not a symlink — skipped"
    return 1
  fi

  ln -s "$target" "$name"
}

echo "→ Linking agent configs..."

# ~/.agents is tracked in this repo and .config/goose/skills/* resolve through
# it, so it is created unconditionally rather than gated on any one agent.
link ".config/agents" "$HOME/.agents" && echo "  ✓ ~/.agents"

# Link config for whichever agents are actually present.
for agent in claude codex goose; do
  command -v "$agent" >/dev/null 2>&1 || [[ -d "$HOME/.$agent" ]] || continue
  mkdir -p "$HOME/.$agent"
  link "../.config/agents/skills" "$HOME/.$agent/skills"
  link "../.config/agents/agents" "$HOME/.$agent/agents"
  echo "  ✓ ~/.$agent"
done
