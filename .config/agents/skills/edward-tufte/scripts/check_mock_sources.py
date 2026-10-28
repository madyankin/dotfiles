#!/usr/bin/env python3
"""Fail a design mock that shows text, numbers or states with no source.

Convention, inside every element marked `data-mock` (the part that pretends to
be the product; commentary outside it is not checked):

  data-src="api/app/models/x.rb:31 profit_expected"  real source: path under
      --root, line, and a token that must appear on that line (field, enum
      value, or the exact text the code emits)
  data-src="proposed: no run-progress field"  not in code; the page must style
      [data-src^="proposed"] so the reader sees it
  data-src="ui: expand caret"  a control that claims nothing about data; may
      not contain a digit

Every text node in a frame needs a data-src on itself or an ancestor below the
frame. Prints the ledger (source -> text it covers), proposed rows first.

  python3 -I check_mock_sources.py mock.html [--root ~/Code]
Exit 0 = clean, 1 = problems listed under FAIL.
"""

import argparse
import os
import re
import sys
from html.parser import HTMLParser

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}
SKIP = {"script", "style", "title"}


class Mock(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []  # [tag, src, is_frame, entry]
        self.entries = []  # {"src", "text": [...]}
        self.fails = []
        self.frames = 0
        self.css = ""

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        frame = "data-mock" in a
        src = a.get("data-src")
        if frame:
            self.frames += 1
            if src:
                self.fails.append(f"data-src on the data-mock frame itself ({src}); put it on the elements inside")
                src = None
        entry = None
        if src is not None and self.in_frame():
            entry = {"src": src.strip(), "text": []}
            self.entries.append(entry)
        if tag not in VOID:
            self.stack.append([tag, src, frame, entry])

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag not in VOID:
            self.stack.pop()

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i][0] == tag:
                del self.stack[i:]
                return

    def in_frame(self):
        return any(f for _, _, f, _ in self.stack)

    def handle_data(self, data):
        text = " ".join(data.split())
        if not text:
            return
        if self.stack and self.stack[-1][0] == "style":
            self.css += data
        if any(t in SKIP for t, _, _, _ in self.stack) or not self.in_frame():
            return
        for _, _, frame, entry in reversed(self.stack):
            if entry is not None:
                entry["text"].append(text)
                return
            if frame:
                break
        self.fails.append(f"unsourced text in mock: {text[:60]!r}")


def check_ref(src, root):
    m = re.match(r"^(\S+):(\d+)\s+(.+)$", src)
    if not m:
        return "not 'path:line token', 'proposed: …' or 'ui: …'"
    path, line, token = m.group(1), int(m.group(2)), m.group(3)
    full = os.path.join(root, path)
    if not os.path.isfile(full):
        return f"no file {full}"
    with open(full, encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()
    if line < 1 or line > len(lines):
        return f"{path} has {len(lines)} lines, not {line}"
    if token not in lines[line - 1]:
        return f"{token!r} not on {path}:{line}"
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("html")
    ap.add_argument("--root", default=os.path.expanduser("~/Code"))
    args = ap.parse_args()

    p = Mock()
    with open(args.html, encoding="utf-8") as f:
        p.feed(f.read())
    fails = list(p.fails)
    if p.frames == 0:
        fails.append("no element with data-mock: mark the product frame(s)")

    rows = []
    for e in p.entries:
        src, covered = e["src"], " ".join(e["text"])
        if not covered:
            continue
        if src.startswith("proposed:"):
            kind = "proposed"
        elif src.startswith("ui:"):
            kind = "ui"
            if re.search(r"\d", covered):
                fails.append(f"ui source holds a number: {covered[:60]!r}")
        else:
            kind = "code"
            err = check_ref(src, args.root)
            if err:
                fails.append(f"bad source {src!r}: {err}")
        rows.append((kind, src, covered))

    if any(k == "proposed" for k, _, _ in rows) and not re.search(r"\[data-src\^=[\"']?proposed", p.css):
        fails.append('proposed items are not styled: add a CSS rule for [data-src^="proposed"]')

    order = {"proposed": 0, "code": 1, "ui": 2}
    rows.sort(key=lambda r: order[r[0]])
    counts = {k: sum(1 for r in rows if r[0] == k) for k in order}
    print(f"Source ledger: {counts['code']} from code, {counts['proposed']} proposed, {counts['ui']} ui")
    print("| kind | source | shows |\n|---|---|---|")
    for kind, src, covered in rows:
        print(f"| {kind} | `{src}` | {covered[:80]} |")
    if fails:
        print("\nFAIL")
        for f in fails:
            print(f"- {f}")
        sys.exit(1)


if __name__ == "__main__":
    main()
