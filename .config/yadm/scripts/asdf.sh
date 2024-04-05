#!/usr/bin/env bash

git clone https://github.com/asdf-vm/asdf.git ~/.asdf

source $HOME/.asdf/asdf.sh

# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

asdf plugin-add python
asdf install python latest
asdf global python latest

# Ruby
asdf plugin-add ruby
asdf install ruby latest
asdf global ruby latest

# Node
brew install coreutils gnupg
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
asdf plugin-add nodejs
asdf install nodejs latest
asdf global nodejs latest
npm i -g yarn
