#!/usr/bin/env python3
"""Per-repo backlog of findings noticed in passing.

Files live in ~/.config/agents/backlog/<slug>.md, one per repo (worktrees and
clones of the same remote share one file).

  backlog.py add "<finding>" [--where path:line]
  backlog.py list [--all]
  backlog.py done <n> [--note "..."]
  backlog.py drop <n> [--note "..."]
  backlog.py path
  backlog.py --slug _skills add "..."   # write to a named file regardless of cwd
"""
import argparse
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

ITEM = re.compile(r"^- \[ \] (?P<date>\S+) · (?P<meta>.*?) — (?P<text>.*?)(?: \(seen (?P<seen>\d+)×\))?$")


def root():
    return Path.home() / ".config" / "agents" / "backlog"


def git(*args):
    try:
        out = subprocess.run(["git", *args], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return out.stdout.strip() if out.returncode == 0 else ""


def repo_identity():
    """Return (slug, title) for the repo in cwd, or the _global file outside a repo."""
    url = git("remote", "get-url", "origin")
    m = re.search(r"[:/]([^/:]+)/([^/]+?)(?:\.git)?/?$", url)
    if m:
        return f"{m.group(1)}-{m.group(2)}", f"{m.group(1)}/{m.group(2)}"
    common = git("rev-parse", "--path-format=absolute", "--git-common-dir")
    if common:
        name = Path(common).parent.name
        return name, name
    return "_global", "no repo"


class Backlog:
    def __init__(self, path, title):
        self.path, self.title = path, title
        self.open, self.done = [], []
        if path.exists():
            section = None
            for line in path.read_text().splitlines():
                if line.startswith("# Backlog — "):
                    self.title = line.removeprefix("# Backlog — ")
                elif line.startswith("## "):
                    section = line[3:].strip().lower()
                elif line.startswith("- ["):
                    (self.open if section == "open" else self.done).append(line)

    def save(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        def section(name, items):
            return [f"## {name}", "", *items, ""] if items else [f"## {name}", ""]

        body = [f"# Backlog — {self.title}", "", *section("Open", self.open), *section("Done", self.done)]
        self.path.write_text("\n".join(body))

    def take(self, n):
        if not 1 <= n <= len(self.open):
            sys.exit(f"no open item #{n}; there are {len(self.open)}")
        return self.open.pop(n - 1)


def normalize(text):
    return " ".join(text.lower().split())


def cmd_add(bl, finding, where):
    branch = git("branch", "--show-current")
    meta = " · ".join(p for p in (branch, f"`{where}`" if where else "") if p) or "-"
    key = (where or "", normalize(finding))
    for i, line in enumerate(bl.open):
        m = ITEM.match(line)
        if not m:
            continue
        old_where = re.search(r"`([^`]*)`", m["meta"])
        if (old_where[1] if old_where else "", normalize(m["text"])) == key:
            seen = int(m["seen"] or 1) + 1
            bl.open[i] = f"- [ ] {m['date']} · {m['meta']} — {m['text']} (seen {seen}×)"
            bl.save()
            print(f"bumped #{i + 1} (seen {seen}×) in {bl.path}")
            return
    bl.open.append(f"- [ ] {date.today().isoformat()} · {meta} — {' '.join(finding.split())}")
    bl.save()
    print(f"added #{len(bl.open)} to {bl.path}")


def cmd_close(bl, n, note, verb):
    m = ITEM.match(bl.take(n))
    if not m:
        sys.exit(f"item #{n} is not in the expected format; edit {bl.path} by hand")
    mark = "x" if verb == "done" else "~"
    tail = f" — {verb}" + (f": {note}" if note else "")
    bl.done.insert(0, f"- [{mark}] {m['date']} → {date.today().isoformat()} · {m['meta']} — {m['text']}{tail}")
    bl.save()
    print(f"{verb} #{n}: {m['text']}")


def print_open(bl):
    for i, line in enumerate(bl.open, 1):
        print(f"{i}. {line.removeprefix('- [ ] ')}")
    if not bl.open:
        print("(empty)")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--slug", help="file name under ~/.config/agents/backlog instead of the cwd repo")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("add")
    p.add_argument("finding")
    p.add_argument("--where", help="path:line or other locator")
    p = sub.add_parser("list")
    p.add_argument("--all", action="store_true", help="every backlog file with open items")
    for verb in ("done", "drop"):
        p = sub.add_parser(verb)
        p.add_argument("n", type=int)
        p.add_argument("--note")
    sub.add_parser("path")
    args = ap.parse_args(argv)

    slug, title = (args.slug, args.slug) if args.slug else repo_identity()
    bl = Backlog(root() / f"{slug}.md", title)

    if args.cmd == "add":
        cmd_add(bl, args.finding, args.where)
    elif args.cmd in ("done", "drop"):
        cmd_close(bl, args.n, args.note, args.cmd)
    elif args.cmd == "path":
        print(bl.path)
    elif args.all:
        files = sorted(root().glob("*.md")) if root().exists() else []
        for path in files:
            other = Backlog(path, path.stem)
            if other.open:
                print(f"## {other.title} ({path.stem}, {len(other.open)} open)")
                print_open(other)
                print()
    else:
        print(f"## {bl.title} — {bl.path}")
        print_open(bl)


if __name__ == "__main__":
    sys.exit(main())
