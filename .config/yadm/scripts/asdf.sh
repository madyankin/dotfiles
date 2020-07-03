#!/usr/bin/env bash

git clone https://github.com/asdf-vm/asdf.git ~/.asdf

source $HOME/.asdf/asdf.sh
source $HOME/.asdf/completions/asdf.bash


asdf plugin-add python
asdf install python 3.6.5
asdf global python 3.6.5

# Ruby
asdf plugin-add ruby
asdf install ruby 2.5.1
asdf global ruby 2.5.1

# Node
brew install coreutils gnupg 
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
asdf plugin-add nodejs
asdf install nodejs 10.3.0
asdf global nodejs 10.3.0
npm i -g yarn
