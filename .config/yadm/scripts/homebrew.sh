#!/usr/bin/env bash

set -e

# --- Homebrew Bootstrap ---
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# --- Wizard ---
echo ""
echo "╭─────────────────────────────────────╮"
echo "│     Homebrew Install Wizard         │"
echo "╰─────────────────────────────────────╯"
echo ""
echo "  [1] Essentials (CLI, fonts, devtools, productivity)"
echo "  [2] Personal   (music, journaling, books, backups)"
echo "  [3] Both"
echo "  [q] Quit"
echo ""
read -rp "Select option: " choice

install_essentials() {
  echo ""
  echo "→ Installing CLI tools..."
  brew install \
    asdf \
    bat \
    delta \
    git \
    gnupg \
    fd \
    jq \
    htop \
    mas \
    mc \
    neovim \
    pinentry-mac \
    powerlevel10k \
    speedtest-cli \
    yadm

  echo ""
  echo "→ Installing fonts..."
  brew install --cask \
    font-jetbrains-mono \
    font-jetbrains-mono-nerd-font \

  echo ""
  echo "→ Installing essential MAS apps..."
  ensure_mas_login
  mas install 937984704   # Amphetamine
  mas install 425424353   # The Unarchiver
  mas install 1452453066  # Hidden Bar
  mas install 1438243180  # Dark Reader
  mas install 1637438059  # Untrap
  mas install 411643860   # DaisyDisk
  mas install 904280696   # Things 3
}

install_personal() {
  echo ""
  echo "→ Installing music apps..."
  brew install --cask \
    bias-fx \
    guitar-pro

  echo ""
  echo "→ Installing backup & security..."
  brew install --cask \
    arq

  echo ""
  echo "→ Installing personal MAS apps..."
  ensure_mas_login
  mas install 497799835   # Xcode
  mas install 1055511498  # Day One
  mas install 682658836   # GarageBand
  mas install 1481853033  # Strongbox
  mas install 1511185140  # Moneywiz
}

MAS_LOGIN_CHECKED=false
ensure_mas_login() {
  $MAS_LOGIN_CHECKED && return
  MAS_LOGIN_CHECKED=true
  if ! mas account >/dev/null 2>&1; then
    echo "Not signed in to Mac App Store — opening App Store..."
    open -a "App Store"
    read -rp "Press Enter after signing in to continue..."
  fi
}

case "$choice" in
  1)
    install_essentials
    echo ""
    echo "✓ Essentials installed. Run again for personal apps."
    ;;
  2)
    install_personal
    echo ""
    echo "✓ Personal apps installed."
    ;;
  3)
    install_essentials
    install_personal
    echo ""
    echo "✓ All apps installed."
    ;;
  q|Q)
    echo "Cancelled."
    exit 0
    ;;
  *)
    echo "Invalid option."
    exit 1
    ;;
esac
