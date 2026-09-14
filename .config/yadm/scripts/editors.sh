#!/usr/bin/env bash

# VS Code settings sync.
# Settings live in ~/.config/yadm/editors/ and are symlinked into VS Code.

set -e

EDITORS_DIR="$HOME/.config/yadm/editors"
CODE_USER="$HOME/Library/Application Support/Code/User"

# Symlink settings.json, keybindings.json and snippets/ into the editor's User
# directory.
link_settings() {
  local user_dir="$1"

  mkdir -p "$user_dir"

  for file in settings.json keybindings.json; do
    if [[ -f "$EDITORS_DIR/$file" ]]; then
      rm -f "$user_dir/$file"
      ln -sf "$EDITORS_DIR/$file" "$user_dir/$file"
      echo "  ✓ $file"
    fi
  done

  if [[ -d "$EDITORS_DIR/snippets" ]]; then
    rm -rf "$user_dir/snippets"
    ln -sf "$EDITORS_DIR/snippets" "$user_dir/snippets"
    echo "  ✓ snippets/"
  fi
}

setup_symlinks() {
  echo "→ Linking VS Code settings..."
  link_settings "$CODE_USER"
}

# Record the currently installed extensions in extensions.txt.
save_extensions() {
  echo "→ Saving extensions..."

  if ! command -v code &>/dev/null; then
    echo "  ✗ VS Code not found"
    exit 1
  fi

  code --list-extensions 2>/dev/null | sort -u > "$EDITORS_DIR/extensions.txt"
  echo "  ✓ Saved: $(wc -l < "$EDITORS_DIR/extensions.txt" | tr -d ' ') extensions"
}

# Install everything listed in extensions.txt.
install_extensions() {
  echo "→ Installing extensions..."

  if ! command -v code &>/dev/null; then
    echo "  ✗ VS Code not found"
    return
  fi

  if [[ -f "$EDITORS_DIR/extensions.txt" ]]; then
    while IFS= read -r ext; do
      [[ -z "$ext" ]] && continue
      code --install-extension "$ext" --force 2>/dev/null || true
    done < "$EDITORS_DIR/extensions.txt"
    echo "  ✓ Extensions installed"
  fi
}

# Reconcile installed extensions against extensions.txt: install what is
# missing, remove what is not listed.
sync_extensions() {
  echo "→ Syncing extensions..."

  if ! command -v code &>/dev/null; then
    echo "  ✗ VS Code not found"
    return
  fi

  local desired installed to_install to_remove
  desired=$(grep -v '^$' "$EDITORS_DIR/extensions.txt" 2>/dev/null \
            | tr '[:upper:]' '[:lower:]' | sort -u)
  installed=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -u)

  to_install=$(comm -23 <(echo "$desired") <(echo "$installed"))
  if [[ -n "$to_install" ]]; then
    echo "$to_install" | while IFS= read -r ext; do
      [[ -n "$ext" ]] && code --install-extension "$ext" --force 2>/dev/null || true
    done
    echo "  ✓ installed $(echo "$to_install" | wc -l | tr -d ' ') extensions"
  fi

  to_remove=$(comm -13 <(echo "$desired") <(echo "$installed"))
  if [[ -n "$to_remove" ]]; then
    echo "$to_remove" | while IFS= read -r ext; do
      [[ -n "$ext" ]] && code --uninstall-extension "$ext" 2>/dev/null || true
    done
    echo "  ✓ removed $(echo "$to_remove" | wc -l | tr -d ' ') extensions"
  fi

  [[ -z "$to_install" && -z "$to_remove" ]] && echo "  ✓ already in sync"
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
  save|save:code)
    save_extensions
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
    echo "Usage: $0 {setup|save|install|sync|link}"
    exit 1
    ;;
esac
