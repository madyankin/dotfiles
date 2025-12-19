#!/usr/bin/env bash

# install homebrew if it's missing
if ! command -v brew >/dev/null 2>&1; then
  echo "  Installing homebrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

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

brew install --cask \
  nikitabobko/tap/aerospace \
  alfred \
  arq \
  appcleaner \
  bias-fx \
  firefox \
  fliqlo \
  guitar-pro \
  iina \
  iterm2 \
  imagealpha \
  imageoptim \
  karabiner-elements \
  keybase \
  skim \
  obsidian \
  orbstack \
  parallels \
  vlc \
  font-jetbrains-mono \
  font-hack-nerd-font

# --- Mac App Store login ---
log "Checking Mac App Store login"
if ! mas account >/dev/null 2>&1; then
  log "Not signed in to Mac App Store — opening login prompt"
  mas signin --dialog
fi

mas install 937984704  # Amphetamine
mas install 413969927  # AudioBookBinder
mas install 411643860   # DaisyDisk
mas install 1055511498  # Day One
mas install 682658836   # GarageBand
mas install 425424353   # The Unarchiver
mas install 992076693   # MindNode
mas install 904280696   # Things 3
mas install 497799835     # Xcode



