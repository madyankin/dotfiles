# Completions and plugins.

fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit bashcompinit
compinit
bashcompinit

# powerlevel10k must load before zplug so the theme is in place first.
[[ -r /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]] \
  && source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

source ~/.zplug/init.zsh

zplug "lib/completion", from:oh-my-zsh
zplug "lib/history", from:oh-my-zsh
zplug "lib/directories", from:oh-my-zsh
zplug "lib/grep", from:oh-my-zsh
zplug "lib/termsupport", from:oh-my-zsh

zplug "plugins/bundler", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/docker-compose", from:oh-my-zsh
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/macos", from:oh-my-zsh
zplug "plugins/npm", from:oh-my-zsh
zplug "plugins/yarn", from:oh-my-zsh

zplug "zsh-users/zsh-syntax-highlighting", defer:2

# Auto-install missing plugins
zplug check || zplug install
zplug load
