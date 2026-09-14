# Completions and plugins.
#
# ORDER IS LOAD-BEARING in this file:
#   1. fpath  — every directory holding _completion files
#   2. compinit — scans fpath; anything added after it is invisible
#   3. plugins — they call compdef, which needs compinit already run
#   4. syntax highlighting LAST — it wraps ZLE widgets the others redefine
#
# zplug used to do steps 1, 3 and 4 and cost 0.58s cold / 0.14s warm. Sourcing
# the same files it clones costs 0.07s: the framework was the expense, not the
# plugins (10-40ms each). zplug stays installed and still owns CLONING and
# UPDATING (`dot update` runs `zplug update`); it is just out of the hot path.

# ------------------------------------------------------------------- paths --

ZPLUG_HOME="${ZPLUG_HOME:-$HOME/.zplug}"
ZSH="$ZPLUG_HOME/repos/robbyrussell/oh-my-zsh"
export ZSH

# oh-my-zsh.sh normally sets this. Pointed at ~/.cache rather than inside the
# clone, so refreshing the repo does not wipe the cached completions.
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

# Plugin directories that ship _completion files (_bundler, _docker-compose,
# _security, _yarn) plus the cache dir where docker/npm write generated ones.
fpath=(
  /opt/homebrew/share/zsh/site-functions
  "$ZSH_CACHE_DIR/completions"
  "$ZSH/plugins/bundler"
  "$ZSH/plugins/docker"
  "$ZSH/plugins/docker-compose"
  "$ZSH/plugins/macos"
  "$ZSH/plugins/yarn"
  $fpath
)

# ---------------------------------------------------------------- compinit --

# compinit is expensive. Rebuild the dump at most once a day; every other shell
# loads it with -C, which skips the security scan of every fpath directory.
# (#qN.mh+24) means "exists, plain file, modified more than 24h ago".
autoload -Uz compinit bashcompinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit -d "$ZDOTDIR/.zcompdump"
else
  compinit -C -d "$ZDOTDIR/.zcompdump"
fi
bashcompinit

# Compile the dump so zsh mmaps bytecode instead of re-parsing the text.
if [[ -s "$ZDOTDIR/.zcompdump" && ( ! -s "$ZDOTDIR/.zcompdump.zwc" || "$ZDOTDIR/.zcompdump" -nt "$ZDOTDIR/.zcompdump.zwc" ) ]]; then
  zcompile -R -- "$ZDOTDIR/.zcompdump" 2>/dev/null
fi

# ------------------------------------------------------------------ prompt --

# powerlevel10k before the plugins, so the theme is in place first.
[[ -r /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]] \
  && source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# ----------------------------------------------------- oh-my-zsh libs/plugins --

# functions.zsh and git.zsh come FIRST: they define the helpers the rest depend
# on. Omitting them silently cost `take`, `mkcd`, `omz_urlencode`,
# `open_command`, `alias_value`, `default` and — the ones that actually break
# things — `git_current_branch` / `parse_git_dirty`, which git-plugin aliases
# such as ggpush and gpsup call at runtime. zplug had loaded them implicitly.
_omz_libs=(functions git completion history directories grep termsupport)
_omz_plugins=(bundler docker docker-compose git macos npm yarn)

# Nothing cloned yet (fresh machine)? Let zplug do the one job it still has.
if [[ ! -d "$ZSH" && -f "$ZPLUG_HOME/init.zsh" ]]; then
  source "$ZPLUG_HOME/init.zsh"
  zplug "robbyrussell/oh-my-zsh", use:"lib/*.zsh"
  zplug "zsh-users/zsh-syntax-highlighting", defer:2
  zplug install
fi

for _f in $_omz_libs; do
  [[ -r "$ZSH/lib/$_f.zsh" ]] && source "$ZSH/lib/$_f.zsh"
done
for _f in $_omz_plugins; do
  [[ -r "$ZSH/plugins/$_f/$_f.plugin.zsh" ]] && source "$ZSH/plugins/$_f/$_f.plugin.zsh"
done
unset _f _omz_libs _omz_plugins

# Two autoloads that came from oh-my-zsh libs we do NOT load:
#   colors         <- lib/theme-and-appearance.zsh (populates $fg/$bg arrays)
#   regexp-replace <- lib/vcs_info.zsh (p10k replaces vcs_info entirely)
# Autoloading the functions directly is cheaper than sourcing either lib.
autoload -Uz colors regexp-replace 2>/dev/null && colors 2>/dev/null

# Must be last: it hooks the ZLE widgets every other plugin may have
# redefined. This is what zplug's `defer:2` meant.
_zsh_hl="$ZPLUG_HOME/repos/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -r "$_zsh_hl" ]] && source "$_zsh_hl"

# ------------------------------------------------------------------ upkeep --

# Verify the clones exist — but not on every shell. `zplug check` stats every
# repo, which was most of the old cost. The marker is keyed to this file's
# mtime, so editing the lists above re-checks exactly once.
_zplug_marker="${XDG_CACHE_HOME:-$HOME/.cache}/zplug-checked"
# /usr/bin/stat by absolute path: zsh's own `stat` builtin (zsh/stat) shadows
# it once loaded and takes different flags.
_zplug_sig="$(/usr/bin/stat -f '%m-%z' "$ZDOTDIR/plugins.zsh" 2>/dev/null)"
if [[ ! -f "$_zplug_marker" || "$(<"$_zplug_marker" 2>/dev/null)" != "$_zplug_sig" ]]; then
  if [[ -d "$ZSH" && -r "$_zsh_hl" ]]; then
    mkdir -p "${_zplug_marker:h}"
    print -r -- "$_zplug_sig" > "$_zplug_marker"
  elif [[ -f "$ZPLUG_HOME/init.zsh" ]]; then
    source "$ZPLUG_HOME/init.zsh" && zplug install
  fi
fi
unset _zplug_marker _zplug_sig _zsh_hl
