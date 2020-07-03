#!/usr/bin/env bash

brew install tmux

git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm

$HOME/.tmux/plugins/tpm/bin/clean_plugins
$HOME/.tmux/plugins/tpm/bin/install_plugins
