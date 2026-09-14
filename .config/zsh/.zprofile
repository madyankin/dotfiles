# Login-shell init.
#
# Setting ZDOTDIR relocates every zsh startup file, so zsh stops reading
# ~/.zprofile. Tools write there without asking (OrbStack does), so source it
# rather than move its contents here and have them silently overwritten.

[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
