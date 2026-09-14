# Defining a theme

A theme is a directory here with three files. Nothing registers it: `theme.sh
list` finds any directory containing `palette.light.sh`.

```
.config/yadm/themes/<name>/
  palette.light.sh    required — every colour, light mode
  palette.dark.sh     required — every colour, dark mode
  meta.sh             required — things that are SELECTED rather than coloured
  backgrounds/        optional — wallpapers, cycled by `dot background next`
  generated/          written by the renderer; gitignored
```

## The fastest route

Copy a theme that already works and edit the hex values:

```bash
cd ~/.config/yadm/themes
cp -R github mytheme
rm -rf mytheme/generated
$EDITOR mytheme/palette.dark.sh mytheme/palette.light.sh mytheme/meta.sh
dot theme set mytheme
```

`dot theme set` writes `themes/.active` (untracked, per-machine), regenerates
every app's config, then nudges the apps that need it.

## Palette format

Flat `KEY=value`, one per line, `#rrggbb` lowercase. Not TOML and not JSON: the
file is sourced by bash **and** parsed by the Python renderer, so both halves of
the engine read the same file with no converter between them. `#` starts a
comment.

Both mode files carry the **same keys** — only the values differ. A missing key
is not silently tolerated; the renderer aborts and names every placeholder it
could not resolve.

### Required keys

| Group | Keys |
|---|---|
| identity | `MODE` (`light`\|`dark`), `NAME` |
| ANSI | `ANSI_00` … `ANSI_15`, in the standard order: black, red, green, yellow, blue, magenta, cyan, white, then the eight bright variants |
| surfaces | `BACKGROUND`, `BACKGROUND_DARKER`, `BACKGROUND_LIGHTER`, `FOREGROUND`, `FOREGROUND_DIM`, `SELECTION_BG`, `SELECTION_FG`, `CURSOR`, `CURSOR_TEXT`, `BORDER` |
| accents | `ACCENT`, `ACCENT_ALT` |
| syntax | `SYN_COMMENT`, `SYN_STRING`, `SYN_KEYWORD`, `SYN_FUNCTION`, `SYN_TYPE`, `SYN_CONSTANT`, `SYN_VARIABLE`, `SYN_OPERATOR`, `SYN_ERROR`, `SYN_WARNING`, `SYN_HINT`, `SYN_DIFF_ADD`, `SYN_DIFF_DEL`, `SYN_DIFF_CHANGE` |

The `SYN_*` group exists because the editors are generated. Point them at ANSI
values if you have no better idea — that is what the seed themes do — but a
theme with real syntax colours will look considerably better in nvim, VS Code
and Zed.

`BACKGROUND_DARKER` / `_LIGHTER` are explicit stops rather than computed
blends, because a hand-picked stop beats a computed one where it matters. Use
`{{ mix A B 15% }}` in a template when you do want the blend.

## meta.sh

Not every app takes colours. Some only take a *name*, and those go here:

```sh
BAT_LIGHT="GitHub"          # must exist in `bat --list-themes`
BAT_DARK="OneHalfDark"
HTOP_SCHEME_LIGHT=3         # htop has no theme file, only color_scheme 0..6
HTOP_SCHEME_DARK=0          # 3 = Light Terminal, 0 = Default (inherits the bg)
ITERM_PROFILE="Github"      # the iTerm2 profile to regenerate
```

`bat` ships its own themes and we pick the closest pair rather than generating
a `.tmTheme` and re-running `bat cache --build` on every render. `dot theme
doctor` checks that the names you put here actually exist.

## What gets generated

One `dot theme set` writes all of these, for **both** modes:

Ghostty (palette, plus the app icon) · tmux · p10k · fzf · btop · htop ·
mc (truecolor + an ANSI fallback) · nvim · VS Code (as a local extension —
VS Code cannot load a theme from a bare path) · Zed · the iTerm2 dynamic
profile · Terminal.app profiles.

**Alfred is deliberately NOT generated.** It stays on the imported "Alfred
macOS Ventura" theme, bound to both the light and dark slots, with Alfred's own
`nativedarkmode` doing the light/dark adaptation. A launcher tinted to editor
colours looked wrong next to everything else on screen.

tmux, p10k, fzf and `ls` are rendered in **ANSI indices only, never hex**. That
is deliberate: the terminal swaps its own palette when macOS flips appearance,
so those repaint in already-running shells with no daemon and no reload.

## Adding a new target

Drop a template in `templates/`. The suffix decides how it is rendered:

| Suffix | Rendered |
|---|---|
| `*.mode.tpl` | once per mode, with that mode's palette plus `{{MODE}}` / `{{MODE_CAP}}` |
| `*.ansi.tpl` | once, with **no** palette hex offered — forces ANSI index space |
| `*.dual.tpl` | once, with both palettes as `{{L_*}}` and `{{D_*}}` |

Then add the output path and its group to `TARGETS` in
`scripts/theme_render.py`. Groups are what `--skip` / `--only` accept:
`terminal`, `shell`, `tui`, `editors`, `native`.

Placeholders: `{{KEY}}`, `{{KEY_STRIP}}` (no `#`), `{{KEY_RGB}}` (`r,g,b`),
`{{KEY_RGBA}}` (`#rrggbbff`, for Alfred), `{{ mix A B 15% }}`.

A hand-written file in the theme directory overrides the generated one.

## Useful commands

```bash
dot theme list                 # * marks active
dot theme set <name>
dot theme render               # regenerate without switching
dot theme render --skip editors # keep the hand-tuned nvim/VS Code/Zed themes
dot theme doctor               # palette vs what the apps actually use
dot font list                  # installed monospace families
dot font set "<family>" [size]
dot background next
```

## Two apps need a nudge

Ghostty caches its theme file, so `Cmd+Shift+,` reloads it after a palette
edit. Neovim needs `:source $MYVIMRC` or a restart. Everything else repaints on
its own. `theme.sh` prints this reminder after every render.
