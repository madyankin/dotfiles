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

echo "→ Installing mise..."
if ! command -v mise >/dev/null 2>&1; then
  sudo apt install -y gpg sudo wget curl
  sudo install -dm 755 /etc/apt/keyrings
  wget -qO - https://mise.jdx.dev/gpg-key.pub \
    | gpg --dearmor \
    | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt update
  sudo apt install -y mise
fi

echo "→ Installing JetBrains Mono..."
curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh | bash
