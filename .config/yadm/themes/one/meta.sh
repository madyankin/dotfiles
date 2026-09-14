# Per-app selections for the one theme.
#
# Two kinds of value live here:
#   - names of things we GENERATE (ghostty/nvim/vscode/zed/btop) — these are
#     fixed and identical across themes, since the files are rewritten per theme;
#   - names of things we only SELECT (bat, iTerm2 profile, htop scheme) —
#     stock themes chosen to match this palette, and what `theme.sh doctor`
#     checks each app against.

# bat ships its own themes; we pick the closest pair rather than generating a
# .tmTheme and having to run `bat cache --build` on every render.
BAT_LIGHT="OneHalfLight"
BAT_DARK="OneHalfDark"

# htop has no theme file at all, only color_scheme 0..6.
# 3 = Light Terminal (built for light backgrounds), 0 = Default (inherits the
# terminal background, which is what we want in dark mode).
HTOP_SCHEME_LIGHT=3
HTOP_SCHEME_DARK=0

# iTerm2 stays as the fallback terminal; this is the profile theme.sh regenerates.
ITERM_PROFILE="One"
