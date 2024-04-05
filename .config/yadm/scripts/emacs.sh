#!/usr/bin/env bash

brew tap d12frosted/emacs-plus
brew install emacs-plus --with-nobu417-big-sur-icon --with-native-comp
brew services start d12frosted/emacs-plus/emacs-plus

git clone --depth 1 https://github.com/hlissner/doom-emacs $HOME/.emacs.d
$HOME/.emacs.d/bin/doom install
