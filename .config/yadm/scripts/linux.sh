#!/bin/bash

echo "Installing packages"
sudo apt update
sudo apt install \
    build-essentials \
    gcc \
    git \
    bat \
    neovim \
    graphviz \
    texlive-latex-extra \
    sqlite3


echo "Installing fonts..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"
