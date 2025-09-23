# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload bashcompinit
bashcompinit

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



case "$OSTYPE" in
	darwin*)
		export MANPAGER="sh -c 'col -bx | bat -l man -p'"
		
    alias clean-derived-data="rm -rf ~/Library/Developer/Xcode/DerivedData"
		
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

