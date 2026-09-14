#!/usr/bin/env python3
"""Render one theme's palette into every app's config.

Invoked only by theme.sh, which owns the CLI, the lock and the state file.

Why Python and not bash: three targets cannot be produced with sed. Terminal.app
stores each colour as an NSKeyedArchiver-encoded NSColor blob, the iTerm2 dynamic
profile is a plist, and Alfred/VS Code/Zed want JSON. plistlib and json cover all
of it from the standard library, and doing the colour maths here is what makes
Omarchy's {{ mix a b 15% }} possible at all.

Stdlib only. Must run on /usr/bin/python3 (3.9): no tomllib, no match.
"""

import argparse
import json
import os
import pathlib
import plistlib
import re
import sys

HOME = pathlib.Path.home()
YADM = HOME / ".config/yadm"
THEMES = YADM / "themes"
TEMPLATES = THEMES / "templates"

MODES = ("light", "dark")

# template basename -> (output path pattern, group)
# {mode} is substituted for .mode.tpl templates. Group names are what
# `theme.sh render --skip <group>` accepts.
TARGETS = [
    ("ghostty.mode.tpl",       "~/.config/ghostty/themes/yadm-{mode}",                     "terminal"),
    ("ghostty-icon.dual.tpl",  "~/.config/ghostty/icon.conf",                              "terminal"),
    ("tmux.ansi.tpl",          "~/.config/tmux/theme.conf",                                "terminal"),
    ("p10k-colors.ansi.tpl",   "~/.config/zsh/p10k-colors.zsh",                            "shell"),
    ("fzf-colors.ansi.tpl",    "~/.config/zsh/fzf-colors.zsh",                             "shell"),
    ("btop.mode.tpl",          "~/.config/btop/themes/yadm-{mode}.theme",                  "tui"),
    ("htoprc.mode.tpl",        "~/.config/htop/htoprc.{mode}",                             "tui"),
    ("mc-skin.mode.tpl",       "~/.local/share/mc/skins/yadm-{mode}.ini",                  "tui"),
    ("mc-skin-ansi.ansi.tpl",  "~/.local/share/mc/skins/yadm-ansi.ini",                    "tui"),
    ("nvim-colors.mode.tpl",   "~/.config/nvim/lua/yadm-theme/{mode}.lua",                 "editors"),
    ("vscode-theme.mode.tpl",  "~/.vscode/extensions/yadm-theme/themes/yadm-{mode}.json",  "editors"),
    ("vscode-package.dual.tpl", "~/.vscode/extensions/yadm-theme/package.json",             "editors"),
    ("zed-theme.dual.tpl",     "~/.config/zed/themes/yadm.json",                           "editors"),
]

ITERM_PROFILE_GUID = "yadm-theme-00000000-0000-0000-0000-000000000001"


# --------------------------------------------------------------- palette io --

def read_kv(path):
    """Parse a flat KEY=value file. Deliberately not a shell parser: the palette
    format is restricted to exactly this so both halves of the engine can read
    it. Strips one layer of surrounding quotes."""
    out = {}
    if not path.exists():
        return out
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        k = k.strip()
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
            v = v[1:-1]
        out[k] = v
    return out


# ---------------------------------------------------------------- colour ops --

HEX = re.compile(r"^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$")


def rgb(c):
    if not HEX.match(c or ""):
        raise ValueError("not a hex colour: %r" % (c,))
    h = c[1:]
    if len(h) == 3:
        h = "".join(ch * 2 for ch in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def hexstr(t):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(x))) for x in t)


def mix(a, b, pct):
    """pct% of a, the rest b. Omarchy's {{ mix }}."""
    ar, ag, ab = rgb(a)
    br, bg, bb = rgb(b)
    f = pct / 100.0
    return hexstr((ar * f + br * (1 - f), ag * f + bg * (1 - f), ab * f + bb * (1 - f)))


# ------------------------------------------------------------- substitution --

PLACEHOLDER = re.compile(r"\{\{\s*(.+?)\s*\}\}")


def resolve(expr, vars_):
    """One placeholder. Supported forms:
         KEY              -> #rrggbb (or the raw value for non-colours)
         KEY_STRIP        -> rrggbb
         KEY_RGB          -> r,g,b
         KEY_RGBA         -> #rrggbbff
         mix A B 15%      -> blended hex
    """
    parts = expr.split()
    if parts and parts[0] == "mix":
        if len(parts) != 4:
            raise ValueError("mix takes 3 arguments: %r" % expr)
        a = vars_.get(parts[1], parts[1])
        b = vars_.get(parts[2], parts[2])
        pct = float(parts[3].rstrip("%"))
        return mix(a, b, pct)

    key = parts[0]
    if key in vars_:
        return vars_[key]
    for suffix, fn in (
        ("_STRIP", lambda v: v.lstrip("#")),
        ("_RGB", lambda v: "%d,%d,%d" % rgb(v)),
        ("_RGBA", lambda v: v + "ff"),
    ):
        if key.endswith(suffix):
            base = key[: -len(suffix)]
            if base in vars_:
                return fn(vars_[base])
    raise KeyError(key)


def render(text, vars_, origin):
    missing = []

    def sub(m):
        try:
            return resolve(m.group(1), vars_)
        except KeyError as e:
            missing.append(str(e))
            return m.group(0)
    out = PLACEHOLDER.sub(sub, text)
    if missing:
        raise SystemExit("theme_render: %s: unknown placeholder(s): %s"
                         % (origin, ", ".join(sorted(set(missing)))))
    return out


# ------------------------------------------------------------------- writing --

def write(path, content, written):
    """Write only when the content actually changed, so an unchanged render does
    not touch mtimes (and does not make the 2-hourly sync commit noise)."""
    path = pathlib.Path(os.path.expanduser(str(path)))
    path.parent.mkdir(parents=True, exist_ok=True)
    data = content if isinstance(content, bytes) else content.encode()
    if path.exists() and path.read_bytes() == data:
        written.append(("=", path))
        return
    tmp = path.with_name(path.name + ".tmp%d" % os.getpid())
    tmp.write_bytes(data)
    tmp.replace(path)          # atomic within the same directory
    written.append(("+", path))


# -------------------------------------------------------- native generators --

def nscolor(hexcolor):
    """An NSKeyedArchiver-encoded NSColor, as Terminal.app stores colours.
    The payload is an ASCII component string inside the archive, which is why
    this is buildable with plistlib alone and needs no pyobjc."""
    r, g, b = (c / 255.0 for c in rgb(hexcolor))
    archive = {
        "$version": 100000,
        "$archiver": "NSKeyedArchiver",
        "$top": {"root": plistlib.UID(1)},
        "$objects": [
            "$null",
            {
                "$class": plistlib.UID(2),
                "NSColorSpace": 1,                      # calibrated RGB
                "NSRGB": ("%.6f %.6f %.6f" % (r, g, b)).encode() + b"\x00",
            },
            {"$classes": ["NSColor", "NSObject"], "$classname": "NSColor"},
        ],
    }
    return plistlib.dumps(archive, fmt=plistlib.FMT_BINARY)


TERMINAL_KEYS = [
    ("BackgroundColor", "BACKGROUND"),
    ("TextColor", "FOREGROUND"),
    ("TextBoldColor", "FOREGROUND"),
    ("SelectionColor", "SELECTION_BG"),
    ("CursorColor", "CURSOR"),
    ("ANSIBlackColor", "ANSI_00"),
    ("ANSIRedColor", "ANSI_01"),
    ("ANSIGreenColor", "ANSI_02"),
    ("ANSIYellowColor", "ANSI_03"),
    ("ANSIBlueColor", "ANSI_04"),
    ("ANSIMagentaColor", "ANSI_05"),
    ("ANSICyanColor", "ANSI_06"),
    ("ANSIWhiteColor", "ANSI_07"),
    ("ANSIBrightBlackColor", "ANSI_08"),
    ("ANSIBrightRedColor", "ANSI_09"),
    ("ANSIBrightGreenColor", "ANSI_10"),
    ("ANSIBrightYellowColor", "ANSI_11"),
    ("ANSIBrightBlueColor", "ANSI_12"),
    ("ANSIBrightMagentaColor", "ANSI_13"),
    ("ANSIBrightCyanColor", "ANSI_14"),
    ("ANSIBrightWhiteColor", "ANSI_15"),
]


def terminal_app_profile(pal, mode, theme):
    """A .terminal profile. Font is deliberately absent: Terminal.app archives
    it as an NSFont, which is a much bigger archive to hand-build, and the font
    is already set once in the profile the user keeps."""
    d = {
        "name": "yadm-%s" % mode,   # matches the filename, which is what Terminal.app keys the profile by
        "type": "Window Settings",
        "ProfileCurrentVersion": 2.07,
        "columnCount": 120,
        "rowCount": 34,
        "useOptionAsMetaKey": True,
        "ShowWindowSettingsNameInTitle": False,
    }
    for tkey, pkey in TERMINAL_KEYS:
        d[tkey] = nscolor(pal[pkey])
    return plistlib.dumps(d, fmt=plistlib.FMT_XML)


def iterm_dynamic_profile(pal_light, pal_dark, font, meta):
    """iTerm2 watches DynamicProfiles/ and applies changes to RUNNING sessions,
    which is the closest thing macOS has to Omarchy's retint dispatch."""
    def comps(c):
        r, g, b = (x / 255.0 for x in rgb(c))
        return {"Red Component": r, "Green Component": g, "Blue Component": b,
                "Color Space": "sRGB", "Alpha Component": 1.0}

    prof = {
        "Name": "yadm",
        "Guid": ITERM_PROFILE_GUID,
        "Use Separate Colors for Light and Dark Mode": True,
        "Normal Font": "%s %s" % (font.get("FONT_FAMILY", "Menlo"),
                                  font.get("FONT_SIZE", "13")),
        "Terminal Type": "xterm-256color",
        "Custom Directory": "Recycle",
    }
    pairs = [("Light", pal_light), ("Dark", pal_dark)]
    for label, pal in pairs:
        for i in range(16):
            prof["Ansi %d Color (%s)" % (i, label)] = comps(pal["ANSI_%02d" % i])
        prof["Background Color (%s)" % label] = comps(pal["BACKGROUND"])
        prof["Foreground Color (%s)" % label] = comps(pal["FOREGROUND"])
        prof["Bold Color (%s)" % label] = comps(pal["FOREGROUND"])
        prof["Cursor Color (%s)" % label] = comps(pal["CURSOR"])
        prof["Cursor Text Color (%s)" % label] = comps(pal["CURSOR_TEXT"])
        prof["Selection Color (%s)" % label] = comps(pal["SELECTION_BG"])
        prof["Selected Text Color (%s)" % label] = comps(pal["SELECTION_FG"])
        prof["Link Color (%s)" % label] = comps(pal["ACCENT"])
    return json.dumps({"Profiles": [prof]}, indent=2)


def bat_config(meta):
    return "\n".join([
        "# Generated by scripts/theme.sh — do not edit.",
        "#",
        "# auto:system reads AppleInterfaceStyle per invocation, so already-open",
        "# shells follow a light/dark flip with no reload. BAT_THEME is left unset",
        "# on purpose: git-delta reads it and would be pinned by it.",
        '--theme="auto:system"',
        '--theme-light="%s"' % meta.get("BAT_LIGHT", "GitHub"),
        '--theme-dark="%s"' % meta.get("BAT_DARK", "OneHalfDark"),
        "--style=numbers,changes,header",
        "",
    ])


def btop_config(theme_mode_default):
    return "\n".join([
        "# Generated by scripts/theme.sh — do not edit.",
        "#",
        "# theme_background = False is what makes btop inherit the terminal",
        "# background, so the surface follows a light/dark flip immediately.",
        "# Graph colours only change on restart.",
        'color_theme = "yadm-%s"' % theme_mode_default,
        "theme_background = False",
        "truecolor = True",
        "vim_keys = True",
        "",
    ])



# ------------------------------------------------------------------- fonts --

def apply_fonts(font, written):
    """Patch the font family/size into VS Code's and Zed's settings.

    These two are hand-maintained JSONC files, not generated ones, so the
    values are rewritten in place with a targeted regex — json.load would
    choke on the comments and json.dump would strip them.

    This exists because font.sh claims to be the single source for the
    monospace family. It was not: only Ghostty, the iTerm2 profile and
    Terminal.app were fed from it, while these two quietly kept whatever was
    typed into them years ago.
    """
    family = font.get("FONT_FAMILY")
    size = font.get("FONT_SIZE")
    if not family:
        return

    targets = [
        # path, [(regex, replacement)]
        (YADM / "editors/settings.json", [
            (r'("editor\.fontFamily"\s*:\s*")[^"]*(")',
             lambda m: m.group(1) + family + ", Menlo, Monaco, monospace" + m.group(2)),
            (r'("editor\.fontSize"\s*:\s*)[0-9.]+', lambda m: m.group(1) + str(size)),
            (r'("terminal\.integrated\.fontSize"\s*:\s*)[0-9.]+',
             lambda m: m.group(1) + str(size)),
        ]),
        (HOME / ".config/zed/settings.json", [
            (r'("buffer_font_family"\s*:\s*")[^"]*(")',
             lambda m: m.group(1) + family + m.group(2)),
            (r'("buffer_font_size"\s*:\s*)[0-9.]+', lambda m: m.group(1) + str(size)),
        ]),
    ]

    for path, subs in targets:
        if not path.exists():
            continue
        text = original = path.read_text()
        for pattern, repl in subs:
            text = re.sub(pattern, repl, text)
        if text != original:
            write(path, text, written)
        else:
            written.append(("=", path))

# ---------------------------------------------------------------------- main --

def current_mode():
    """What macOS is showing right now. Used only to pick single-value defaults
    (btop.conf's color_theme); everything else is generated for both modes."""
    try:
        import subprocess
        out = subprocess.run(["defaults", "read", "-g", "AppleInterfaceStyle"],
                             capture_output=True, text=True).stdout.strip()
        return "dark" if out == "Dark" else "light"
    except Exception:
        return "light"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("theme")
    ap.add_argument("--skip", action="append", default=[],
                    help="group to skip: terminal shell tui editors native fonts")
    ap.add_argument("--only", action="append", default=[])
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    tdir = THEMES / args.theme
    if not tdir.is_dir():
        raise SystemExit("theme_render: no such theme: %s" % tdir)

    pal = {}
    for mode in MODES:
        p = tdir / ("palette.%s.sh" % mode)
        if not p.exists():
            raise SystemExit("theme_render: missing %s" % p)
        pal[mode] = read_kv(p)

    meta = read_kv(tdir / "meta.sh")
    font = read_kv(THEMES / "font.sh")

    htoprc_base = (HOME / ".config/htop/htoprc.base")
    htoprc_base = htoprc_base.read_text().rstrip("\n") if htoprc_base.exists() else ""

    def wanted(group):
        if args.only:
            return group in args.only
        return group not in args.skip

    written = []

    # ---- template targets
    for tpl_name, out_pattern, group in TARGETS:
        if not wanted(group):
            continue
        tpl = TEMPLATES / tpl_name
        if not tpl.exists():
            raise SystemExit("theme_render: missing template %s" % tpl)
        body = tpl.read_text()

        if tpl_name.endswith(".dual.tpl"):
            v = dict(font)
            v.update(meta)
            for prefix, mode in (("L_", "light"), ("D_", "dark")):
                for k, val in pal[mode].items():
                    v[prefix + k] = val
            write(out_pattern, render(body, v, tpl_name), written)

        elif tpl_name.endswith(".ansi.tpl"):
            # No palette hex offered on purpose: these outputs must stay in
            # ANSI index space, which is what lets them follow the terminal.
            v = dict(font)
            v.update(meta)
            write(out_pattern, render(body, v, tpl_name), written)

        else:  # .mode.tpl
            for mode in MODES:
                v = dict(font)
                v.update(meta)
                v.update(pal[mode])
                v["MODE"] = mode
                v["MODE_CAP"] = mode.capitalize()
                v["HTOPRC_BASE"] = htoprc_base
                v["HTOP_SCHEME"] = meta.get("HTOP_SCHEME_%s" % mode.upper(), "0")
                write(out_pattern.format(mode=mode), render(body, v, tpl_name), written)

    # ---- native generators (plists / JSON that no template can express)
    if wanted("native"):
        for mode in MODES:
            write(tdir / "generated" / ("yadm-%s.terminal" % mode),
                  terminal_app_profile(pal[mode], mode, args.theme), written)
        write("~/Library/Application Support/iTerm2/DynamicProfiles/yadm-theme.json",
              iterm_dynamic_profile(pal["light"], pal["dark"], font, meta), written)

    # ---- small config files that select rather than colour
    if wanted("fonts"):
        apply_fonts(font, written)

    if wanted("tui"):
        write("~/.config/bat/config", bat_config(meta), written)
        write("~/.config/btop/btop.conf", btop_config(current_mode()), written)

    if not args.quiet:
        for flag, path in written:
            try:
                rel = path.relative_to(HOME)
                shown = "~/%s" % rel
            except ValueError:
                shown = str(path)
            print("  %s %s" % (flag, shown))
        changed = sum(1 for f, _ in written if f == "+")
        print("  %d file(s) written, %d unchanged" % (changed, len(written) - changed))


if __name__ == "__main__":
    sys.exit(main())
