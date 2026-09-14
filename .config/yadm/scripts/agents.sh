#!/usr/bin/env bash

set -e

selected_agents=()
declare -A npm_pkg=([claude]="@anthropic-ai/claude-code" [codex]="@openai/codex")

install_claude() {
  if ! command -v claude &>/dev/null; then
    npm install -g @anthropic-ai/claude-code
    echo "  ✓ claude installed"
  else
    echo "  ✓ claude already installed"
  fi
  selected_agents+=(claude)
}

install_codex() {
  if ! command -v codex &>/dev/null; then
    npm install -g @openai/codex
    echo "  ✓ codex installed"
  else
    echo "  ✓ codex already installed"
  fi
  selected_agents+=(codex)
}

install_cursor() {
  if ! brew list --cask cursor &>/dev/null 2>&1; then
    brew install --cask cursor
    echo "  ✓ cursor installed"
  else
    echo "  ✓ cursor already installed"
  fi
  selected_agents+=(cursor)
}

install_goose() {
  if ! command -v goose &>/dev/null; then
    brew install --cask block-goose
    echo "  ✓ goose installed"
  else
    echo "  ✓ goose already installed"
  fi
}

is_selected() {
  local agent="$1"
  for s in "${selected_agents[@]}"; do
    [[ "$s" == "$agent" ]] && return 0
  done
  return 1
}

remove_unselected() {
  echo "→ Removing unselected agents..."
  # npm-based: uninstall the CLI package
  for agent in claude codex; do
    if ! is_selected "$agent" && command -v "$agent" &>/dev/null; then
      npm uninstall -g "${npm_pkg[$agent]}"
      echo "  ✓ $agent removed"
    fi
  done
  # cursor: uninstall the app and remove config symlinks
  if ! is_selected cursor && brew list --cask cursor &>/dev/null 2>&1; then
    brew uninstall --cask --force cursor
    rm -f ~/.cursor/skills ~/.cursor/agents
    echo "  ✓ cursor removed"
  fi
  # goose uses ~/.config/goose/ (not symlinked), so nothing to unlink
}

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

link_configs() {
  echo "→ Linking agent configs..."

  # ~/.agents is tracked in the dotfiles repo and .config/goose/skills/*
  # resolve through it, so it is created unconditionally — not gated on any
  # one agent being selected.
  link ".config/agents" "$HOME/.agents" && echo "  ✓ ~/.agents"

  for agent in "${selected_agents[@]}"; do
    mkdir -p "$HOME/.$agent"
    link "../.config/agents/skills" "$HOME/.$agent/skills"
    link "../.config/agents/agents" "$HOME/.$agent/agents"
    echo "  ✓ ~/.$agent"
  done
}

# --- Wizard ---
echo ""
echo "╭─────────────────────────────────────╮"
echo "│        Agent Install Wizard         │"
echo "╰─────────────────────────────────────╯"
echo ""
echo "  [1] Claude  (Anthropic)"
echo "  [2] Codex   (OpenAI)"
echo "  [3] Cursor  (Cursor)"
echo "  [4] Goose   (Block)"
echo "  [a] All"
echo "  [q] Skip"
echo ""
read -rp "Select options (e.g. 1 3): " -a choices

for choice in "${choices[@]}"; do
  case "$choice" in
    1) install_claude ;;
    2) install_codex ;;
    3) install_cursor ;;
    4) install_goose ;;
    a|A)
      install_claude
      install_codex
      install_cursor
      install_goose
      break
      ;;
    q|Q)
      echo "Skipping."
      break
      ;;
    *)
      echo "Unknown option: $choice"
      exit 1
      ;;
  esac
done

remove_unselected
link_configs
