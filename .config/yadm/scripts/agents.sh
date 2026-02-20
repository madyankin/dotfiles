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

install_opencode() {
  if ! brew list --formula opencode &>/dev/null 2>&1; then
    brew install opencode
    echo "  ✓ opencode installed"
  else
    echo "  ✓ opencode already installed"
  fi
  selected_agents+=(opencode)
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
  # opencode: uninstall formula (skills are loaded from ~/.agents)
  if ! is_selected opencode && brew list --formula opencode &>/dev/null 2>&1; then
    brew uninstall opencode
    rm -f ~/.opencode/skills ~/.opencode/agents
    echo "  ✓ opencode removed"
  fi
  # goose uses ~/.config/goose/ (not symlinked), so nothing to unlink
}

link_configs() {
  echo "→ Linking agent configs..."
  if is_selected opencode; then
    if [[ ! -e ~/.agents || -L ~/.agents ]]; then
      ln -sfn .config/agents ~/.agents
      echo "  ✓ ~/.agents linked"
    else
      echo "  ✓ ~/.agents exists (skipped)"
    fi
  fi
  for agent in "${selected_agents[@]}"; do
    if [[ "$agent" == "opencode" ]]; then
      continue
    fi
    mkdir -p ~/."$agent"
    ln -sfn ../.config/agents/skills ~/."$agent/skills"
    ln -sfn ../.config/agents/agents ~/."$agent/agents"
    echo "  ✓ ~/.$agent linked"
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
echo "  [5] OpenCode (SST)"
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
    5) install_opencode ;;
    a|A)
      install_claude
      install_codex
      install_cursor
      install_goose
      install_opencode
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
