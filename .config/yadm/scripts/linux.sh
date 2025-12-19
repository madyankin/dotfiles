#!/bin/bash

set -e

echo "→ Updating packages..."
sudo apt update

echo "→ Installing packages..."
sudo apt install -y \
  build-essential \
  gcc \
  git \
  bat \
  neovim \
  sqlite3

echo "→ Installing JetBrains Mono..."
curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh | bash
