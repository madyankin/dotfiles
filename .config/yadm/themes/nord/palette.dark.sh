# GitHub — dark mode.
# Seeded from the iTerm2 profile of the same name: these 16 values were
# already hand-tuned, so adopting them makes the refactor a visual no-op.
#
# Flat KEY=value: sourceable by bash AND parseable by the Python renderer,
# with no converter in between. Values are #rrggbb, lowercase.

MODE=dark
NAME="Nord Dark"

# --- the 16 ANSI slots, in order ---
ANSI_00=#3b4252
ANSI_01=#bf616a
ANSI_02=#a3be8c
ANSI_03=#ebcb8b
ANSI_04=#81a1c1
ANSI_05=#b48ead
ANSI_06=#88c0d0
ANSI_07=#e5e9f0
ANSI_08=#4c566a
ANSI_09=#bf616a
ANSI_10=#a3be8c
ANSI_11=#ebcb8b
ANSI_12=#81a1c1
ANSI_13=#b48ead
ANSI_14=#8fbcbb
ANSI_15=#eceff4

# --- surfaces ---
BACKGROUND=#2e3440
BACKGROUND_DARKER=#272c36
BACKGROUND_LIGHTER=#3b4252
FOREGROUND=#d8dee9
FOREGROUND_DIM=#7b88a1
SELECTION_BG=#434c5e
SELECTION_FG=#eceff4
CURSOR=#d8dee9
CURSOR_TEXT=#2e3440
BORDER=#4c566a

# --- accents ---
ACCENT=#88c0d0
ACCENT_ALT=#b48ead

# --- syntax roles ---
# Editors are generated from these, so they need names a theme can mean,
# not raw ANSI indices. Bright variants (8-15) where a role wants lift.
SYN_COMMENT=#616e88
SYN_STRING=#a3be8c
SYN_KEYWORD=#81a1c1
SYN_FUNCTION=#88c0d0
SYN_TYPE=#8fbcbb
SYN_CONSTANT=#b48ead
SYN_VARIABLE=#d8dee9
SYN_OPERATOR=#81a1c1
SYN_ERROR=#bf616a
SYN_WARNING=#ebcb8b
SYN_HINT=#88c0d0
SYN_DIFF_ADD=#a3be8c
SYN_DIFF_DEL=#bf616a
SYN_DIFF_CHANGE=#ebcb8b
