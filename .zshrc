autoload bashcompinit
bashcompinit

source ~/.zplug/init.zsh

#zplug "themes/robbyrussell", from:oh-my-zsh, as:theme
#zplug "themes/kphoen", from:oh-my-zsh, as:theme

export SPACESHIP_GIT_SYMBOL=''
export SPACESHIP_KUBECTL_CONTEXT_SHOW=false
export SPACESHIP_GCLOUD_SHOW=false
export SPACESHIP_CONDA_SHOW=false
zplug denysdovhan/spaceship-prompt, use:spaceship.zsh, from:github, as:theme

zplug "lib/completion", from:oh-my-zsh
zplug "lib/history", from:oh-my-zsh
zplug "lib/directories", from:oh-my-zsh
zplug "lib/grep", from:oh-my-zsh
zplug "lib/termsupport", from:oh-my-zsh

zplug "plugins/bundler", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/docker-compose", from:oh-my-zsh
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/heroku", from:oh-my-zsh
zplug "plugins/macos", from:oh-my-zsh
zplug "plugins/react-native", from:oh-my-zsh
zplug "plugins/npm", from:oh-my-zsh
zplug "plugins/yarn", from:oh-my-zsh

zplug "zsh-users/zsh-syntax-highlighting"
  
# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load #--verbose

# Enable colored output for ls
unset LSCOLORS
export CLICOLOR=1
export CLICOLOR_FORCE=1

setopt auto_cd
bindkey -e

alias rld='source ~/.zshrc'
alias de='docker exec -i -t'
alias dstats='docker stats --format "table {{.Name}}:\t{{.MemUsage}}\t{{.CPUPerc}}"'
alias sync-dotfiles='~/.config/yadm/scripts/commit-and-push.sh'
alias nvim-config='~/.config/nvim && nvim .'

git-clean-branches() {
    git fetch
    git remote prune origin
    git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D
}

g++-run() {
    g++ -lstdc++ -std=c++14 -pipe -O2 -Wall $1 && ./a.out
}

# Codi
# Usage: codi [filetype] [filename]
codi() {
  local syntax="${1:-python}"
  shift
  vim -c \
    "let g:startify_disable_at_vimenter = 1 |\
    set bt=nofile ls=0 noru nonu nornu |\
    hi ColorColumn ctermbg=NONE |\
    hi VertSplit ctermbg=NONE |\
    hi NonText ctermfg=0 |\
    ALEDisable |\
    Codi $syntax" "$@"
}


case "$OSTYPE" in
	darwin*)
		export MANPAGER="sh -c 'col -bx | bat -l man -p'"
		
    alias clean-derived-data="rm -rf ~/Library/Developer/Xcode/DerivedData"
    alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
		
    source $HOME/.asdf/asdf.sh
    # append completions to fpath
    fpath=(${ASDF_DIR}/completions $fpath)
    # initialise completions with ZSH's compinit
    autoload -Uz compinit && compinit

		;;
	linux*)
		alias bat="batcat"
		export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
		;;
	*) ;;
esac


[ -s "$HOME/.zshenv" ] && source $HOME/.zshenv
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh



test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

MACHINE_SPECIFIC_CONF=~/.zshrc.machine-specific

if [[ -e $MACHINE_SPECIFIC_CONF ]]; then
    source $MACHINE_SPECIFIC_CONF
fi
eval "$(gh copilot alias -- zsh)"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/madyankin/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
