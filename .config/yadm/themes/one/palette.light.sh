# One — light mode.
# Seeded from the iTerm2 profile of the same name: these 16 values were
# already hand-tuned, so adopting them makes the refactor a visual no-op.
#
# Flat KEY=value: sourceable by bash AND parseable by the Python renderer,
# with no converter in between. Values are #rrggbb, lowercase.

MODE=light
NAME="One Light"

# --- the 16 ANSI slots, in order ---
ANSI_00=#24292f
ANSI_01=#cf222e
ANSI_02=#116329
ANSI_03=#4d2d00
ANSI_04=#0969da
ANSI_05=#8250df
ANSI_06=#1b7c83
ANSI_07=#6e7781
ANSI_08=#57606a
ANSI_09=#a40e26
ANSI_10=#1a7f37
ANSI_11=#633c01
ANSI_12=#218bff
ANSI_13=#a475f9
ANSI_14=#3192aa
ANSI_15=#8c959f

# --- surfaces ---
BACKGROUND=#f6f8fa
BACKGROUND_DARKER=#e7e9eb
BACKGROUND_LIGHTER=#ffffff
FOREGROUND=#1f2328
FOREGROUND_DIM=#808386
SELECTION_BG=#add6ff
SELECTION_FG=#1f2328
CURSOR=#1f2328
CURSOR_TEXT=#f6f8fa
BORDER=#c0c3c6

# --- accents ---
ACCENT=#0969da
ACCENT_ALT=#8250df

# --- syntax roles ---
# Editors are generated from these, so they need names a theme can mean,
# not raw ANSI indices. Bright variants (8-15) where a role wants lift.
SYN_COMMENT=#57606a
SYN_STRING=#116329
SYN_KEYWORD=#cf222e
SYN_FUNCTION=#8250df
SYN_TYPE=#4d2d00
SYN_CONSTANT=#0969da
SYN_VARIABLE=#1f2328
SYN_OPERATOR=#1b7c83
SYN_ERROR=#cf222e
SYN_WARNING=#4d2d00
SYN_HINT=#1b7c83
SYN_DIFF_ADD=#116329
SYN_DIFF_DEL=#cf222e
SYN_DIFF_CHANGE=#0969da
