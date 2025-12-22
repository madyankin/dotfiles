#!/usr/bin/env bash

# Cursor & VS Code settings sync
# Settings stored in ~/.config/yadm/editors/ and symlinked to both editors

set -e

EDITORS_DIR="$HOME/.config/yadm/editors"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
CODE_USER="$HOME/Library/Application Support/Code/User"

# --- Symlink settings ---
link_settings() {
  local target="$1"
  local user_dir="$2"
  local name=$(basename "$2")
  
  mkdir -p "$user_dir"
  
  for file in settings.json keybindings.json; do
    if [[ -f "$EDITORS_DIR/$file" ]]; then
      rm -f "$user_dir/$file"
      ln -sf "$EDITORS_DIR/$file" "$user_dir/$file"
      echo "  ✓ $file"
    fi
  done
  
  # Snippets directory
  if [[ -d "$EDITORS_DIR/snippets" ]]; then
    rm -rf "$user_dir/snippets"
    ln -sf "$EDITORS_DIR/snippets" "$user_dir/snippets"
    echo "  ✓ snippets/"
  fi
}

setup_symlinks() {
  echo "→ Linking Cursor settings..."
  link_settings "$EDITORS_DIR" "$CURSOR_USER"
  
  echo "→ Linking VS Code settings..."
  link_settings "$EDITORS_DIR" "$CODE_USER"
}

# --- Extensions ---
save_extensions() {
  echo "→ Saving extensions..."
  
  if command -v cursor &>/dev/null; then
    cursor --list-extensions > "$EDITORS_DIR/extensions-cursor.txt" 2>/dev/null || true
    echo "  ✓ Cursor: $(wc -l < "$EDITORS_DIR/extensions-cursor.txt" | tr -d ' ') extensions"
  fi
  
  if command -v code &>/dev/null; then
    code --list-extensions > "$EDITORS_DIR/extensions-code.txt" 2>/dev/null || true
    echo "  ✓ VS Code: $(wc -l < "$EDITORS_DIR/extensions-code.txt" | tr -d ' ') extensions"
  fi
}

install_extensions() {
  echo "→ Installing extensions..."
  
  if command -v cursor &>/dev/null && [[ -f "$EDITORS_DIR/extensions-cursor.txt" ]]; then
    while IFS= read -r ext; do
      [[ -n "$ext" ]] && cursor --install-extension "$ext" --force 2>/dev/null || true
    done < "$EDITORS_DIR/extensions-cursor.txt"
    echo "  ✓ Cursor extensions installed"
  fi
  
  if command -v code &>/dev/null && [[ -f "$EDITORS_DIR/extensions-code.txt" ]]; then
    while IFS= read -r ext; do
      [[ -n "$ext" ]] && code --install-extension "$ext" --force 2>/dev/null || true
    done < "$EDITORS_DIR/extensions-code.txt"
    echo "  ✓ VS Code extensions installed"
  fi
}

# --- Main ---
case "${1:-setup}" in
  setup)
    echo ""
    echo "╭─────────────────────────────────────╮"
    echo "│       Editor Settings Sync          │"
    echo "╰─────────────────────────────────────╯"
    setup_symlinks
    install_extensions
    echo ""
    echo "✓ Done"
    ;;
  save)
    save_extensions
    ;;
  install)
    install_extensions
    ;;
  link)
    setup_symlinks
    ;;
  *)
    echo "Usage: $0 {setup|save|install|link}"
    exit 1
    ;;
esac

