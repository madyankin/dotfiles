# One — dark mode.
# Seeded from the iTerm2 profile of the same name: these 16 values were
# already hand-tuned, so adopting them makes the refactor a visual no-op.
#
# Flat KEY=value: sourceable by bash AND parseable by the Python renderer,
# with no converter in between. Values are #rrggbb, lowercase.

MODE=dark
NAME="One Dark"

# --- the 16 ANSI slots, in order ---
ANSI_00=#1e2127
ANSI_01=#e06c75
ANSI_02=#98c379
ANSI_03=#d19a66
ANSI_04=#3f92ee
ANSI_05=#c678dd
ANSI_06=#56b6c2
ANSI_07=#abb2bf
ANSI_08=#5c6370
ANSI_09=#e06c75
ANSI_10=#98c379
ANSI_11=#d19a66
ANSI_12=#5777c6
ANSI_13=#c678dd
ANSI_14=#56b6c2
ANSI_15=#ffffff

# --- surfaces ---
BACKGROUND=#16191d
BACKGROUND_DARKER=#121417
BACKGROUND_LIGHTER=#2d3034
FOREGROUND=#abb2bf
FOREGROUND_DIM=#686d76
SELECTION_BG=#5c6370
SELECTION_FG=#3a3f4b
CURSOR=#bbbbbb
CURSOR_TEXT=#ffffff
BORDER=#3b3f46

# --- accents ---
ACCENT=#3f92ee
ACCENT_ALT=#c678dd

# --- syntax roles ---
# Editors are generated from these, so they need names a theme can mean,
# not raw ANSI indices. Bright variants (8-15) where a role wants lift.
SYN_COMMENT=#5c6370
SYN_STRING=#98c379
SYN_KEYWORD=#e06c75
SYN_FUNCTION=#c678dd
SYN_TYPE=#d19a66
SYN_CONSTANT=#3f92ee
SYN_VARIABLE=#abb2bf
SYN_OPERATOR=#56b6c2
SYN_ERROR=#e06c75
SYN_WARNING=#d19a66
SYN_HINT=#56b6c2
SYN_DIFF_ADD=#98c379
SYN_DIFF_DEL=#e06c75
SYN_DIFF_CHANGE=#3f92ee
