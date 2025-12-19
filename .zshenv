# --- PATH ---
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="./bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Deduplicate PATH (zsh only)
[[ -n "${ZSH_VERSION:-}" ]] && typeset -U path

# --- Locale ---
export LC_ALL=en_US.UTF-8

# --- Editor ---
export EDITOR=nvim

# --- FZF ---
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# --- Tools ---
export BAT_THEME=base16
export GPG_TTY=$(tty)
