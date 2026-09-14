# Aliases. OS-specific ones live in .zshrc's platform block.

alias rld='source $ZDOTDIR/.zshrc'
alias de='docker exec -it'
alias dstats='docker stats --format "table {{.Name}}:\t{{.MemUsage}}\t{{.CPUPerc}}"'
alias sync-dotfiles='~/.config/yadm/scripts/commit-and-push.sh'
alias nvim-config='cd ~/.config/nvim && nvim .'
alias mc="mc --nosubshell"
alias ca="claude --enable-auto-mode"
alias cy="claude --dangerously-skip-permissions"
