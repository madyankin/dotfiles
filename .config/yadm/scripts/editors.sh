#!/usr/bin/env bash

# Cursor & VS Code settings sync
# Settings stored in ~/.config/yadm/editors/ and symlinked to both editors

set -e

EDITORS_DIR="$HOME/.config/yadm/editors"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
CODE_USER="$HOME/Library/Application Support/Code/User"

# Symlink settings.json, keybindings.json, and snippets/ to an editor's User directory.
# Arguments:
#   $1 - source directory (EDITORS_DIR)
#   $2 - target User directory (e.g., ~/Library/Application Support/Cursor/User)
link_settings() {
  local target="$1"
  local user_dir="$2"
  
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

# Create symlinks for both Cursor and VS Code to share settings from EDITORS_DIR.
setup_symlinks() {
  echo "→ Linking Cursor settings..."
  link_settings "$EDITORS_DIR" "$CURSOR_USER"
  
  echo "→ Linking VS Code settings..."
  link_settings "$EDITORS_DIR" "$CODE_USER"
}

# Collect extensions from both editors, merge and dedupe into extensions.txt.
# Files:
#   extensions.txt             - shared (installed to both editors)
#   extensions-cursor-only.txt - Cursor-specific (manual)
#   extensions-code-only.txt   - VS Code-specific (manual)
# Create editor-specific extensions files manually when needed.
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

# Save extensions from Cursor only.
save_cursor_extensions() {
  echo "→ Saving Cursor extensions..."
  
  if ! command -v cursor &>/dev/null; then
    echo "  ✗ Cursor not found"
    exit 1
  fi
  
  cursor --list-extensions 2>/dev/null | sort -u > "$EDITORS_DIR/extensions.txt"
  echo "  ✓ Saved: $(wc -l < "$EDITORS_DIR/extensions.txt" | tr -d ' ') extensions"
}

# Save extensions from VS Code only.
save_code_extensions() {
  echo "→ Saving VS Code extensions..."
  
  if ! command -v code &>/dev/null; then
    echo "  ✗ VS Code not found"
    exit 1
  fi
  
  code --list-extensions 2>/dev/null | sort -u > "$EDITORS_DIR/extensions.txt"
  echo "  ✓ Saved: $(wc -l < "$EDITORS_DIR/extensions.txt" | tr -d ' ') extensions"
}

# Install extensions from tracked files.
# Shared extensions go to both editors; editor-specific extensions to their respective editor.
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

# Sync extensions: install missing, remove unlisted.
# Arguments:
#   $1 - editor command (cursor or code)
#   $2 - editor name for display
sync_editor_extensions() {
  local cmd="$1"
  local name="$2"
  
  if ! command -v "$cmd" &>/dev/null; then
    echo "  ✗ $name not found"
    return
  fi
  
  # Build list of desired extensions (shared + editor-specific)
  local desired=""
  [[ -f "$EDITORS_DIR/extensions.txt" ]] && desired=$(cat "$EDITORS_DIR/extensions.txt")
  if [[ -f "$EDITORS_DIR/extensions-${cmd}-only.txt" ]]; then
    desired=$(printf "%s\n%s" "$desired" "$(cat "$EDITORS_DIR/extensions-${cmd}-only.txt")")
  fi
  desired=$(echo "$desired" | grep -v '^$' | tr '[:upper:]' '[:lower:]' | sort -u)
  
  # Get currently installed
  local installed
  installed=$("$cmd" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -u)
  
  # Install missing
  local to_install
  to_install=$(comm -23 <(echo "$desired") <(echo "$installed"))
  if [[ -n "$to_install" ]]; then
    echo "$to_install" | while IFS= read -r ext; do
      [[ -n "$ext" ]] && "$cmd" --install-extension "$ext" --force 2>/dev/null || true
    done
    echo "  ✓ $name: installed $(echo "$to_install" | wc -l | tr -d ' ') extensions"
  fi
  
  # Remove unlisted
  local to_remove
  to_remove=$(comm -13 <(echo "$desired") <(echo "$installed"))
  if [[ -n "$to_remove" ]]; then
    echo "$to_remove" | while IFS= read -r ext; do
      [[ -n "$ext" ]] && "$cmd" --uninstall-extension "$ext" 2>/dev/null || true
    done
    echo "  ✓ $name: removed $(echo "$to_remove" | wc -l | tr -d ' ') extensions"
  fi
  
  [[ -z "$to_install" && -z "$to_remove" ]] && echo "  ✓ $name: already in sync"
}

sync_extensions() {
  echo "→ Syncing extensions..."
  sync_editor_extensions cursor Cursor
  sync_editor_extensions code "VS Code"
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
  save:cursor)
    save_cursor_extensions
    ;;
  save:code)
    save_code_extensions
    ;;
  install)
    install_extensions
    ;;
  sync)
    sync_extensions
    ;;
  link)
    setup_symlinks
    ;;
  *)
    echo "Usage: $0 {setup|save|save:cursor|save:code|install|sync|link}"
    exit 1
    ;;
esac

