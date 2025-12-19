#!/usr/bin/env bash

set -e

# Set zsh as default shell (skip if already set)
if [[ "$SHELL" != */zsh ]]; then
  chsh -s /bin/zsh
fi

# Install zplug (skip if exists)
if [[ ! -d "$HOME/.zplug" ]]; then
  git clone --depth 1 https://github.com/zplug/zplug "$HOME/.zplug"
fi
