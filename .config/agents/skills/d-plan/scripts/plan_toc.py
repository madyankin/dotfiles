#!/usr/bin/env python3
"""Write a clickable table of contents into a plan file.

Usage: plan_toc.py PLAN.md

Links every `## ` heading with GitHub's anchor rules, so the links work on
GitHub and in editors that follow them. The list sits between `<!-- toc -->`
and `<!-- /toc -->`; a missing block goes right under the `# ` title.
Running it again replaces the block, so it stays safe after every edit.
Headings inside code fences and YAML frontmatter are skipped.
"""
import re
import sys

START, END = "<!-- toc -->", "<!-- /toc -->"
BLOCK = re.compile(re.escape(START) + r".*?" + re.escape(END) + r"\n?", re.S)
FENCE = re.compile(r"^\s*(```|~~~)")


def slug(heading, seen):
    base = re.sub(r"[^\w\- ]", "", heading.strip().lower()).replace(" ", "-")
    count = seen.get(base, 0)
    seen[base] = count + 1
    return base if count == 0 else f"{base}-{count}"


def headings(lines):
    fenced = False
    for line in lines:
        if FENCE.match(line):
            fenced = not fenced
        elif not fenced and re.match(r"^#{1,6} ", line):
            level = len(line) - len(line.lstrip("#"))
            yield level, line[level:].strip()


def toc(text):
    seen = {"contents": 1}
    items = []
    for level, title in headings(text.splitlines()):
        anchor = slug(title, seen)
        if level == 2:
            label = title.replace("`", "")
            items.append(f"- [{label}](#{anchor})")
    return "\n".join([START, "## Contents", "", *items, END]) + "\n"


def render(text):
    body = BLOCK.sub("", text)
    block = toc(body)
    lines = body.splitlines(keepends=True)
    fenced = False
    for i, line in enumerate(lines):
        if FENCE.match(line):
            fenced = not fenced
        elif not fenced and line.startswith("# "):
            rest = "".join(lines[i + 1:]).lstrip("\n")
            return "".join(lines[: i + 1]) + "\n" + block + "\n" + rest
    return block + "\n" + body


def split_frontmatter(text):
    match = re.match(r"---\n.*?\n---\n", text, re.S)
    return (match[0], text[match.end():]) if match else ("", text)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        text = f.read()
    with open(path, "w", encoding="utf-8") as f:
        frontmatter, body = split_frontmatter(text)
        f.write(frontmatter + render(body))


if __name__ == "__main__":
    main()
