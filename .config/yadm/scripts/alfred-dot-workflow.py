#!/usr/bin/env python3
"""Generate the `dot` Alfred workflow.

The whole objection to Alfred workflows is that info.plist is a GUI-edited
blob: unreviewable, undiffable, and it drifts from the CLI the moment you add
a subcommand. So this workflow is GENERATED. Nothing here is hand-edited, the
Script Filters read `dot commands --json` at runtime, and adding a bin/dot-*
file makes it appear in Alfred with no edit anywhere.

Three filters, chosen because they are the three things Omarchy's menu is
actually used for:
  dot     <- every subcommand, run in Ghostty
  theme   <- the Style menu: theme, background, font
  agent   <- a task handed to the default coding agent, which is exactly the
             shape Alfred's query box wants
  manual  <- a section of MANUAL.md, listed from its own headings
  tw      <- a new Ghostty window in a directory, replacing the dead
             third-party "New Terminal Window" workflow

Stdlib only; /usr/bin/python3 (3.9).
"""

import pathlib
import plistlib
import sys

HOME = pathlib.Path.home()
WF_DIR = (HOME / ".config/yadm/alfred/Alfred.alfredpreferences/workflows"
          / "user.workflow.D07F1LE5-0000-4000-8000-000000000001")
BUNDLE_ID = "name.madyankin.dot"

DOT = "$HOME/.local/bin/dot"

# Alfred runs scripts with a minimal PATH, so every call is absolute and we
# add Homebrew ourselves — jq is needed by `dot commands --json`.
PRELUDE = 'export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"\n'

FILTER_DOT = PRELUDE + f'{DOT} commands --json\n'

FILTER_THEME = PRELUDE + r'''
T="$HOME/.config/yadm/scripts/theme.sh"
{
  "$T" list | sed 's/^[* ] *//' | while IFS= read -r t; do
    printf 'theme set %s\tswitch the whole palette to %s\n' "$t" "$t"
  done
  printf 'background next\tnext wallpaper for this theme\n'
  printf 'theme render\tregenerate every app colour file\n'
  printf 'theme doctor\treport palette vs app drift\n'
} | /opt/homebrew/bin/jq -R -s 'split("\n")
      | map(select(length > 0) | split("\t"))
      | { items: map({ title: .[0], subtitle: .[1], arg: .[0] }) }'
'''

# `tw` replaces the third-party "New Terminal Window" workflow, whose Script
# Filter listed iTerm2 PROFILES from its plist and whose action drove
# `osascript iterm_new.scpt`. Ghostty has no profiles, and that filter ran on
# `python` — python2, absent from modern macOS — so it was dead code.
#
# The part worth keeping is the DIRECTORY, which Ghostty supports directly via
# --working-directory. So this offers, in order: the front Finder window (the
# old `cdf`), $HOME, an exact path if the query is one, and otherwise
# directories matching the query found with fd under whichever roots exist.
FILTER_TERM = PRELUDE + r'''
Q="$1"
JQ=/opt/homebrew/bin/jq

{
  f="$(osascript -e 'tell application "Finder" to if (count of windows) > 0 then return POSIX path of (target of front window as alias)' 2>/dev/null)"
  [ -n "$f" ] && printf '%s	Finder’s front window
' "${f%/}"

  printf '%s	home
' "$HOME"

  # An exact path typed in the query wins over any search.
  case "$Q" in
    /*|~*) e="${Q/#\~/$HOME}"; [ -d "$e" ] && printf '%s	typed path
' "${e%/}" ;;
  esac

  roots=""
  for r in "$HOME/Code" "$HOME/Projects" "$HOME/Documents" "$HOME/.config"; do
    [ -d "$r" ] && roots="$roots $r"
  done

  if [ -n "$Q" ] && [ -n "$roots" ]; then
    # shellcheck disable=SC2086
    /opt/homebrew/bin/fd -t d -H -a --max-depth 4 -- "$Q" $roots 2>/dev/null | head -25       | while IFS= read -r d; do printf '%s	match
' "${d%/}"; done
  elif [ -n "$roots" ]; then
    # shellcheck disable=SC2086
    /opt/homebrew/bin/fd -t d -H -a --max-depth 1 . $roots 2>/dev/null | head -25       | while IFS= read -r d; do printf '%s	%s
' "${d%/}" "top level"; done
  fi
} | "$JQ" -R -s --arg home "$HOME" 'split("
")
      | map(select(length > 0) | split("	"))
      | unique_by(.[0])
      | { items: map({
            title: (.[0] | sub("^" + $home; "~") ),
            subtitle: .[1],
            arg: .[0]
          }) }'
'''

# Sections come straight from the manual's own headings, so the keyword lists
# whatever the document contains.
FILTER_MANUAL = PRELUDE + f'{DOT} manual --sections-json\n'

FILTER_AGENT = PRELUDE + r'''
Q="$1"
{
  if [ -n "$Q" ]; then
    printf 'agent prompt %s\trun the default agent on this task\n' "$Q"
  fi
  "$HOME/.local/bin/dot" agent list | sed 's/^[* ] *//' | awk 'NF>1 {printf "agent set %s\tmake %s the default agent\n", $1, $1}'
} | /opt/homebrew/bin/jq -R -s 'split("\n")
      | map(select(length > 0) | split("\t"))
      | { items: map({ title: .[0], subtitle: .[1], arg: .[0] }) }'
'''

# `dot` subcommands are interactive (wizards, doctor output you read), so they
# belong in a terminal rather than in Alfred's silent script runner.
#
# Ghostty's `-e` takes a command and its arguments as ARGV, not a shell string:
# `ghostty -e fish --with --args`. Handing it one quoted string makes Ghostty
# treat the whole thing as the program name, and login fails with
# "zsh -l: No such file or directory".
#
# `--initial-command=shell:...` is Ghostty's own documented escape hatch for
# "this really is a shell string, do not guess". The trailing exec keeps the
# window open after the command finishes.
# Ghostty is handed bin/dot-in-terminal as the PROGRAM to exec, with the
# subcommand as plain argv. Not `--initial-command="shell:…"`: that wraps the
# string as
#     login -flp <user> /bin/bash --noprofile --norc -c exec -l <string>
# and the prepended `exec -l` replaces the shell with the first command, so a
# trailing `; exec /bin/zsh -l` never runs and the window dies the moment the
# command finishes. With `-e` there is no shell and no quoting to get wrong.
#
# --wait-after-command stays as a safety net: if dot-in-terminal itself fails to
# exec, Ghostty holds the window instead of closing it before you can read why.
#
# -n is required: without it macOS activates the running Ghostty and discards
# --args entirely. The cost is a new Ghostty INSTANCE per launch; `dot menu`
# (fzf, in the terminal you are already in) exists for when that matters.
#
# --window-save-state=never because the tracked config sets `always`, and every
# fresh instance would otherwise RESTORE the previous session's windows
# alongside the one running the command. A launcher action should open exactly
# one window.
ACTION_TERMINAL = (
    'export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"\n'
    '/usr/bin/open -na Ghostty --args --window-save-state=never '
    '--wait-after-command=true '
    '-e "$HOME/.config/yadm/bin/dot-in-terminal" {query}\n'
)

# The manual is read, not run, so it opens in a terminal like the rest — but
# `dot manual <section>` takes the section title as ONE argument, hence the
# quotes that the other action deliberately does not have.
ACTION_MANUAL = (
    'export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"\n'
    '/usr/bin/open -na Ghostty --args --window-save-state=never '
    '--wait-after-command=true '
    '-e "$HOME/.config/yadm/bin/dot-in-terminal" manual "{query}"\n'
)

# Opens the window itself rather than going through dot-in-terminal: there is
# no command to run and no output to keep on screen, just a shell in a
# directory. Quoted because a path can contain spaces.
ACTION_TERM = (
    'export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"\n'
    '"$HOME/.config/yadm/bin/dot-term" "{query}"\n'
)

# Theme changes are silent and instant; no terminal needed.
ACTION_SILENT = (
    'export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"\n'
    '$HOME/.local/bin/dot {query} >/dev/null 2>&1\n'
)


def script_filter(uid, keyword, title, subtext, script, with_space=True, has_arg=True):
    return {
        "uid": uid,
        "type": "alfred.workflow.input.scriptfilter",
        "version": 3,
        "config": {
            "alfredfiltersresults": True,
            "alfredfiltersresultsmatchmode": 0,
            "argumenttreatemptyqueryasnil": False,
            "argumenttrimmode": 0,
            "argumenttype": 1 if has_arg else 2,
            "escaping": 102,
            "keyword": keyword,
            "queuedelaycustom": 3,
            "queuedelayimmediatelyinitially": True,
            "queuedelaymode": 0,
            "queuemode": 1,
            "runningsubtext": "…",
            "script": script,
            "scriptargtype": 1,
            "scriptfile": "",
            "subtext": subtext,
            "title": title,
            "type": 0,
            "withspace": with_space,
        },
    }


def script_action(uid, script):
    return {
        "uid": uid,
        "type": "alfred.workflow.action.script",
        "version": 2,
        "config": {
            "concurrently": False,
            "escaping": 102,
            "script": script,
            "scriptargtype": 0,
            "scriptfile": "",
            "type": 0,
        },
    }


UIDS = {
    "f_dot":   "A1000000-0000-4000-8000-000000000001",
    "a_dot":   "A1000000-0000-4000-8000-000000000002",
    "f_theme": "A1000000-0000-4000-8000-000000000003",
    "a_theme": "A1000000-0000-4000-8000-000000000004",
    "f_agent": "A1000000-0000-4000-8000-000000000005",
    "a_agent": "A1000000-0000-4000-8000-000000000006",
    "f_manual": "A1000000-0000-4000-8000-000000000007",
    "a_manual": "A1000000-0000-4000-8000-000000000008",
    "f_term": "A1000000-0000-4000-8000-000000000009",
    "a_term": "A1000000-0000-4000-8000-00000000000a",
}


def build():
    objects = [
        script_filter(UIDS["f_dot"], "dot", "dot {query}",
                      "every dot subcommand, run in Ghostty", FILTER_DOT),
        script_action(UIDS["a_dot"], ACTION_TERMINAL),
        script_filter(UIDS["f_theme"], "theme", "{query}",
                      "theme, background, font — the Style menu", FILTER_THEME),
        script_action(UIDS["a_theme"], ACTION_SILENT),
        script_filter(UIDS["f_agent"], "agent", "{query}",
                      "run the default coding agent on a task", FILTER_AGENT),
        script_action(UIDS["a_agent"], ACTION_TERMINAL),
        script_filter(UIDS["f_term"], "tw", "{query}",
                      "new Ghostty window in a directory", FILTER_TERM),
        script_action(UIDS["a_term"], ACTION_TERM),
        script_filter(UIDS["f_manual"], "manual", "{query}",
                      "read a section of the dotfiles manual", FILTER_MANUAL,
                      has_arg=False),
        script_action(UIDS["a_manual"], ACTION_MANUAL),
    ]

    def conn(src, dst):
        return [{"destinationuid": dst, "modifiers": 0,
                 "modifiersubtext": "", "vitoclose": False}]

    connections = {
        UIDS["f_dot"]: conn(UIDS["f_dot"], UIDS["a_dot"]),
        UIDS["f_theme"]: conn(UIDS["f_theme"], UIDS["a_theme"]),
        UIDS["f_agent"]: conn(UIDS["f_agent"], UIDS["a_agent"]),
        UIDS["f_manual"]: conn(UIDS["f_manual"], UIDS["a_manual"]),
        UIDS["f_term"]: conn(UIDS["f_term"], UIDS["a_term"]),
    }

    # Laid out in a column so the graph is readable if it is ever opened.
    uidata = {}
    for i, key in enumerate(["f_dot", "a_dot", "f_theme", "a_theme",
                             "f_agent", "a_agent", "f_manual", "a_manual",
                             "f_term", "a_term"]):
        uidata[UIDS[key]] = {"xpos": 40 if key.startswith("f_") else 340,
                             "ypos": 40 + (i // 2) * 140}

    return {
        "bundleid": BUNDLE_ID,
        "name": "dot",
        "createdby": "generated by scripts/alfred-dot-workflow.py",
        "description": ("Front end for the dotfiles CLI. Generated — do not edit "
                        "in Alfred; re-run the generator instead."),
        "disabled": False,
        "readme": ("Generated by ~/.config/yadm/scripts/alfred-dot-workflow.py.\n\n"
                   "The Script Filters call `dot commands --json`, so they list "
                   "whatever bin/dot-* files exist. Adding a subcommand needs no "
                   "change here.\n\nKeywords: dot, theme, agent."),
        "version": "1.0",
        "webaddress": "",
        "objects": objects,
        "connections": connections,
        "uidata": uidata,
        "variablesdontexport": [],
    }


def main():
    WF_DIR.mkdir(parents=True, exist_ok=True)
    out = WF_DIR / "info.plist"
    data = plistlib.dumps(build(), fmt=plistlib.FMT_XML)
    if out.exists() and out.read_bytes() == data:
        print("  = %s" % out.relative_to(HOME))
        return 0
    out.write_bytes(data)
    print("  + %s" % out.relative_to(HOME))
    print("  Alfred picks up a new workflow on relaunch.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
