# $ZDOTDIR/.zshenv — shim, mirroring the $ZDOTDIR/.zprofile one.
#
# ~/.zshenv exports ZDOTDIR. Once that is in the environment, every NESTED zsh
# (a tmux pane, `zsh -c` from a script, a subshell) reads $ZDOTDIR/.zshenv and
# never looks at ~/.zshenv again. Without this file those shells silently fall
# back to whatever PATH they inherited — which is how a stale ~/.asdf/shims or
# ./bin entry survives long after the config dropped it.
source "$HOME/.zshenv"
