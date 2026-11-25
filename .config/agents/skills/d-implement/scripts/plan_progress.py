#!/usr/bin/env python3
"""Draw where an implementation plan stands, from the plan file alone.

Usage: plan_progress.py PLAN.md [--json]

Reads:
  ## Phase N: Title                      a phase
  #### N. Title [done: <sha>]            a step committed as <sha>
  #### N. Title [done: uncommitted]      a step finished, not committed
  - [x] / - [ ]                          the phase's success checkboxes

A phase is done when every step is marked done, or, with no marks at all,
when every checkbox is ticked. A phase with some steps marked is in progress
and shown with its steps; with none in progress, the first open phase is.
The first unmarked step of the last phase in progress is next.
"""
import json
import re
import sys

PHASE = re.compile(r"^## Phase (\d+):\s*(.+?)\s*$")
STEP = re.compile(r"^#### (\d+)\.\s*(.+?)\s*(?:\[done:\s*([^\]]+)\])?\s*$")
BOX = re.compile(r"^\s*- \[([ xX])\]")


def parse(text):
    title = next((l[2:].strip() for l in text.splitlines() if l.startswith("# ")), "Plan")
    phases = []
    for line in text.splitlines():
        if m := PHASE.match(line):
            phases.append({"number": int(m[1]), "title": m[2], "steps": [], "boxes": [0, 0]})
        elif phases and (m := STEP.match(line)):
            phases[-1]["steps"].append({"number": int(m[1]), "title": m[2], "done": (m[3] or "").strip() or None})
        elif phases and (m := BOX.match(line)):
            phases[-1]["boxes"][1] += 1
            phases[-1]["boxes"][0] += m[1] != " "
    return title, phases


def mark(phases):
    for phase in phases:
        steps, (ticked, total) = phase["steps"], phase["boxes"]
        if not any(step["done"] for step in steps):
            finished = total > 0 and ticked == total
            for step in steps:
                step["done"] = "yes" if finished else None
        marked = [step for step in steps if step["done"]]
        if steps and len(marked) == len(steps) or not steps and total and ticked == total:
            phase["state"] = "done"
        else:
            phase["state"] = "current" if marked else "todo"
    active = [phase for phase in phases if phase["state"] == "current"]
    if not active:
        active = [phase for phase in phases if phase["state"] == "todo"][:1]
        for phase in active:
            phase["state"] = "current"
    if active:
        nxt = next((step for step in active[-1]["steps"] if not step["done"]), None)
        if nxt:
            nxt["next"] = True
    return phases


def counts(phases):
    steps = [step for phase in phases for step in phase["steps"]]
    done = sum(1 for step in steps if step["done"])
    return done, len(steps)


def text(title, phases):
    done, total = counts(phases)
    finished = sum(phase["state"] == "done" for phase in phases)
    share = round(100 * (done / total if total else finished / len(phases)))
    bar = "█" * round(share / 5) + "░" * (20 - round(share / 5))
    lines = [f"{title}", f"{bar} {share}%  ·  {finished} of {len(phases)} phases  ·  {done} of {total} steps", ""]
    icon = {"done": "✓", "current": "▶", "todo": "·"}
    for phase in phases:
        steps = phase["steps"]
        tail = f"   {sum(1 for s in steps if s['done'])}/{len(steps)}" if phase["state"] == "current" and steps else ""
        lines.append(f"{icon[phase['state']]} {phase['number']}. {phase['title']}{tail}")
        if phase["state"] != "current":
            continue
        for step in steps:
            if step["done"] == "uncommitted":
                lines.append(f"    ● {step['number']}. {step['title']}   not committed")
            elif step["done"]:
                sha = "" if step["done"] == "yes" else f"   {step['done']}"
                lines.append(f"    ✓ {step['number']}. {step['title']}{sha}")
            else:
                lines.append(f"    {'→' if step.get('next') else '·'} {step['number']}. {step['title']}"
                             f"{'   next' if step.get('next') else ''}")
    return "\n".join(lines)


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if argv else 2
    with open(argv[0], encoding="utf-8") as handle:
        title, phases = parse(handle.read())
    if not phases:
        print(f"no '## Phase N:' headings in {argv[0]}", file=sys.stderr)
        return 1
    mark(phases)
    if "--json" in argv:
        done, total = counts(phases)
        print(json.dumps({"title": title, "steps_done": done, "steps_total": total, "phases": phases}, indent=2))
    else:
        print(text(title, phases))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
