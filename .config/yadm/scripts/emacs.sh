#!/usr/bin/env bash

brew tap d12frosted/emacs-plus
brew install emacs-plus@27 --with-modern-icon-cg433n
brew services start d12frosted/emacs-plus/emacs-plus@27

git clone --depth 1 https://github.com/hlissner/doom-emacs $HOME/.emacs.d
$HOME/.emacs.d/bin/doom install
