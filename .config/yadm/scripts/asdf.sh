#!/usr/bin/env bash

git clone https://github.com/asdf-vm/asdf.git ~/.asdf

source $HOME/.asdf/asdf.sh

# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit


asdf plugin-add python
asdf install python 3.10.0
asdf global python 3.10.0

# Ruby
asdf plugin-add ruby
asdf install ruby 3.0.3
asdf global ruby 3.0.3

# Node
brew install coreutils gnupg 
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
asdf plugin-add nodejs
asdf install nodejs 17.1.0
asdf global nodejs 17.1.0
npm i -g yarn
