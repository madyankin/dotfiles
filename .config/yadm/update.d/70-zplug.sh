#!/usr/bin/env bash
# dot:step=zsh plugins via zplug
[[ -f "$HOME/.zplug/init.zsh" ]] || { warn "zplug not installed"; return 0 2>/dev/null || exit 0; }
# `zsh -c`, not `zsh -ic`: the interactive form re-runs the whole init, which
# would load zplug twice and print the prompt machinery into the log.
run zsh -c 'source ~/.zplug/init.zsh && zplug update'
# plugins.zsh gates `zplug check` behind a marker keyed to its own mtime;
# clearing it makes the next shell verify the result of this update.
run rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/zplug-checked"
ok "zplug done"
