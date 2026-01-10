# Enable Powerlevel10k instant prompt (keep at top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Completions ---
autoload -Uz compinit bashcompinit
compinit
bashcompinit

# --- Zplug ---
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
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

# --- Options ---
setopt auto_cd
bindkey -e

# --- Colors ---
unset LSCOLORS
export CLICOLOR=1
export CLICOLOR_FORCE=1

# --- Aliases ---
alias rld='source ~/.zshrc'
alias de='docker exec -it'
alias dstats='docker stats --format "table {{.Name}}:\t{{.MemUsage}}\t{{.CPUPerc}}"'
alias sync-dotfiles='~/.config/yadm/scripts/commit-and-push.sh'
alias nvim-config='cd ~/.config/nvim && nvim .'
alias mc="mc --nosubshell"

# --- Functions ---
git-clean-branches() {
  git fetch -p
  git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D
}

g++-run() {
  g++ -lstdc++ -std=c++14 -pipe -O2 -Wall "$1" && ./a.out
}

# --- OS-specific ---
case "$OSTYPE" in
  darwin*)
  
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    alias clean-derived-data="rm -rf ~/Library/Developer/Xcode/DerivedData"
  
    ;;
  
  linux*)
  
    alias bat="batcat"
    export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
  
    ;;
esac

# --- External sources ---
[[ -f ~/.zshenv ]] && source ~/.zshenv
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
[[ -f ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh
[[ -f ~/.zshrc.machine-specific ]] && source ~/.zshrc.machine-specific
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- ASDF ---
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)

export DIRENV_LOG_FORMAT=""
eval "$(direnv hook zsh)"
