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
  3
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
# extensions.txt          - shared (installed to both editors)
# extensions-cursor-only.txt - Cursor-specific
# extensions-code-only.txt   - VS Code-specific

save_extensions() {
  echo "→ Saving extensions..."
  
  local cursor_exts="" code_exts=""
  
  if command -v cursor &>/dev/null; then
    cursor_exts=$(cursor --list-extensions 2>/dev/null || true)
  fi
  
  if command -v code &>/dev/null; then
    code_exts=$(code --list-extensions 2>/dev/null || true)
  fi
  
  # Merge and dedupe into shared extensions
  { echo "$cursor_exts"; echo "$code_exts"; } | grep -v '^$' | sort -u > "$EDITORS_DIR/extensions.txt"
  echo "  ✓ Shared: $(wc -l < "$EDITORS_DIR/extensions.txt" | tr -d ' ') extensions"
}

install_extensions() {
  echo "→ Installing extensions..."
  
  # Shared extensions → both editors
  if [[ -f "$EDITORS_DIR/extensions.txt" ]]; then
    while IFS= read -r ext; do
      [[ -z "$ext" ]] && continue
      command -v cursor &>/dev/null && cursor --install-extension "$ext" --force 2>/dev/null || true
      command -v code &>/dev/null && code --install-extension "$ext" --force 2>/dev/null || true
    done < "$EDITORS_DIR/extensions.txt"
    echo "  ✓ Shared extensions installed"
  fi
  
  # Cursor-only extensions
  if command -v cursor &>/dev/null && [[ -f "$EDITORS_DIR/extensions-cursor-only.txt" ]]; then
    while IFS= read -r ext; do
      [[ -n "$ext" ]] && cursor --install-extension "$ext" --force 2>/dev/null || true
    done < "$EDITORS_DIR/extensions-cursor-only.txt"
    echo "  ✓ Cursor-only extensions installed"
  fi
  
  # VS Code-only extensions
  if command -v code &>/dev/null && [[ -f "$EDITORS_DIR/extensions-code-only.txt" ]]; then
    while IFS= read -r ext; do
      [[ -n "$ext" ]] && code --install-extension "$ext" --force 2>/dev/null || true
    done < "$EDITORS_DIR/extensions-code-only.txt"
    echo "  ✓ VS Code-only extensions installed"
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

