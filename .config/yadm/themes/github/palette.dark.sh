# GitHub — dark mode.
# Seeded from the iTerm2 profile of the same name: these 16 values were
# already hand-tuned, so adopting them makes the refactor a visual no-op.
#
# Flat KEY=value: sourceable by bash AND parseable by the Python renderer,
# with no converter in between. Values are #rrggbb, lowercase.

MODE=dark
NAME="GitHub Dark"

# --- the 16 ANSI slots, in order ---
ANSI_00=#545d68
ANSI_01=#f47067
ANSI_02=#57ab5a
ANSI_03=#c69026
ANSI_04=#539bf5
ANSI_05=#b083f0
ANSI_06=#39c5cf
ANSI_07=#909dab
ANSI_08=#636e7b
ANSI_09=#ff938a
ANSI_10=#6bc46d
ANSI_11=#daaa3f
ANSI_12=#6cb6ff
ANSI_13=#dcbdfb
ANSI_14=#56d4dd
ANSI_15=#cdd9e5

# --- surfaces ---
BACKGROUND=#1c2128
BACKGROUND_DARKER=#161a20
BACKGROUND_LIGHTER=#33373d
FOREGROUND=#adbac7
FOREGROUND_DIM=#6c757f
SELECTION_BG=#264f78
SELECTION_FG=#adbac7
CURSOR=#adbac7
CURSOR_TEXT=#1c2128
BORDER=#404750

# --- accents ---
ACCENT=#539bf5
ACCENT_ALT=#b083f0

# --- syntax roles ---
# Editors are generated from these, so they need names a theme can mean,
# not raw ANSI indices. Bright variants (8-15) where a role wants lift.
SYN_COMMENT=#636e7b
SYN_STRING=#57ab5a
SYN_KEYWORD=#f47067
SYN_FUNCTION=#b083f0
SYN_TYPE=#c69026
SYN_CONSTANT=#539bf5
SYN_VARIABLE=#adbac7
SYN_OPERATOR=#39c5cf
SYN_ERROR=#f47067
SYN_WARNING=#c69026
SYN_HINT=#39c5cf
SYN_DIFF_ADD=#57ab5a
SYN_DIFF_DEL=#f47067
SYN_DIFF_CHANGE=#539bf5
