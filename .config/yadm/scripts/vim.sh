#!/usr/bin/env bash

brew install neovim

export NEOVIM_DIR=$HOME/.config/nvim

mkdir -p $NEOVIM_DIR
rm -f $NEOVIM_DIR/init.vim
ln -s $HOME/.vimrc $NEOVIM_DIR/init.vim

if command -v nvim >/dev/null 2>&1; then
  nvim '+PlugUpdate' '+PlugClean!' '+PlugUpdate' '+qall'
fi

pip3 install neovim
