#!/usr/bin/env python3
"""Draw a BPMN collaboration diagram as inline SVG from a small grid spec. No library, no network.

Usage: python3 bpmn_svg.py spec.json > fragment.svg

Spec:
{
  "id": "overview",
  "title": "accessible name of the diagram",
  "pools": [{"id": "agent", "name": "Agent"}, ...],                      # top to bottom
  "nodes": [{"id": "a1", "pool": "agent", "type": "task", "label": "Preview", "col": 1, "row": 0}, ...],
  "flows": [{"from": "a1", "to": "s1", "label": "preview_campaign"}, ...]
}
type: start | end | task | xor | catch (intermediate message event)
status (optional): new | changed | removed — colors the node and adds a text mark above it.
col: grid column shared by all pools; row: 0 or 1 inside its pool (default 0).
A flow inside one pool is a sequence flow (solid); between pools, a message flow (dashed).
Colors come from the page: currentColor plus CSS variables --bg and --panel.
"""
import json
import sys
from xml.sax.saxutils import escape

COL_W, LEFT, POOL_LABEL = 150, 30, 40
ROW_H, POOL_PAD, POOL_GAP = 92, 14, 34
SIZE = {"task": (124, 60), "start": (34, 34), "end": (34, 34), "catch": (34, 34), "xor": (46, 46)}
CHARS_PER_LINE, LINE_H = 16, 14


def wrap(text, width=CHARS_PER_LINE):
    lines, line = [], ""
    for word in (text or "").split():
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = word
        else:
            line = f"{line} {word}".strip()
    return lines + ([line] if line else [])


def text_block(x, y, text, cls="", width=CHARS_PER_LINE, anchor="middle"):
    lines = wrap(text, width)
    top = y - (len(lines) - 1) * LINE_H / 2
    spans = "".join(f'<tspan x="{x:.0f}" y="{top + i * LINE_H:.0f}">{escape(l)}</tspan>' for i, l in enumerate(lines))
    return f'<text class="{cls}" text-anchor="{anchor}" dominant-baseline="middle">{spans}</text>'


def layout(spec):
    nodes = {n["id"]: dict(n) for n in spec["nodes"]}
    cols = max(n["col"] for n in nodes.values()) + 1
    width = POOL_LABEL + LEFT + cols * COL_W
    y, pools = 6, {}
    for pool in spec["pools"]:
        rows = max([n.get("row", 0) for n in nodes.values() if n["pool"] == pool["id"]] or [0]) + 1
        height = rows * ROW_H + 2 * POOL_PAD
        pools[pool["id"]] = {"name": pool["name"], "box": (6, y, width, height)}
        y += height + POOL_GAP
    for n in nodes.values():
        px, py, _, _ = pools[n["pool"]]["box"]
        w, h = SIZE[n["type"]]
        cx = px + POOL_LABEL + LEFT / 2 + n["col"] * COL_W + COL_W / 2
        cy = py + POOL_PAD + n.get("row", 0) * ROW_H + ROW_H / 2
        n["c"], n["box"] = (cx, cy), (cx - w / 2, cy - h / 2, w, h)
    return pools, nodes, width + 12, y - POOL_GAP + 6


def route(f, nodes, pools):
    s, t = nodes[f["from"]], nodes[f["to"]]
    sx, sy, sw, sh = s["box"]
    tx, ty, tw, th = t["box"]
    if s["pool"] == t["pool"]:
        a, b = (sx + sw, sy + sh / 2), (tx, ty + th / 2)
        if abs(a[1] - b[1]) < 1:
            return "seq", [a, b]
        if s["type"] == "xor" and b[1] > a[1]:
            a = (sx + sw / 2, sy + sh)
            return "seq", [a, (a[0], b[1]), b]
        mx = a[0] + (b[0] - a[0]) / 2
        return "seq", [a, (mx, a[1]), (mx, b[1]), b]
    down = pools[s["pool"]]["box"][1] < pools[t["pool"]]["box"][1]
    a = (sx + sw / 2, sy + sh if down else sy)
    b = (tx + tw / 2, ty if down else ty + th)
    if abs(a[0] - b[0]) < 1:
        return "msg", [a, b]
    tb = pools[t["pool"]]["box"]
    edge = tb[1] - 10 if down else tb[1] + tb[3] + 10
    return "msg", [a, (a[0], edge), (b[0], edge), b]


def flow_label(points, text):
    (ax, ay), (bx, by) = points[len(points) // 2 - 1], points[len(points) // 2]
    if abs(ay - by) < 1:
        return text_block((ax + bx) / 2, ay - 10, text, "fl", 24)
    return text_block(ax + 7, (ay + by) / 2, text, "fl", 24, "start")


def pool_label(cx, cy, height, name):
    lines = wrap(name, max(6, int((height - 8) / 7)))
    first = -(len(lines) - 1) * LINE_H / 2
    spans = "".join(f'<tspan x="0" y="{first + k * LINE_H:.0f}">{escape(l)}</tspan>' for k, l in enumerate(lines))
    return (f'<text class="pl" text-anchor="middle" dominant-baseline="middle" '
            f'transform="translate({cx:.0f} {cy:.0f}) rotate(-90)">{spans}</text>')


MARK = {"new": "new", "changed": "changed", "removed": "removed"}


def node_svg(n):
    status = n.get("status")
    body = node_shape(n)
    if status not in MARK:
        return body
    x, y, w, h = n["box"]
    return (f'<g class="st-{status}">{body}'
            f'<text class="sm" x="{x + w:.0f}" y="{y - 6:.0f}" text-anchor="end">«{MARK[status]}»</text></g>')


def node_shape(n):
    x, y, w, h = n["box"]
    cx, cy = n["c"]
    label = n.get("label", "")
    if n["type"] == "task":
        return f'<rect class="bt" x="{x}" y="{y}" width="{w}" height="{h}" rx="10"/>' + text_block(cx, cy, label)
    if n["type"] == "xor":
        r, d = w / 2, 9
        return (f'<polygon class="bg" points="{cx},{y} {x + w},{cy} {cx},{y + h} {x},{cy}"/>'
                f'<path class="bx" d="M{cx - d} {cy - d} L{cx + d} {cy + d} M{cx + d} {cy - d} L{cx - d} {cy + d}"/>'
                + text_block(x - 8, cy, label, "nl", 16, "end"))
    r = w / 2
    shape = f'<circle class="be be-{n["type"]}" cx="{cx}" cy="{cy}" r="{r}"/>'
    if n["type"] == "catch":
        shape += (f'<circle class="be" cx="{cx}" cy="{cy}" r="{r - 4}"/>'
                  f'<rect class="bm" x="{cx - 8}" y="{cy - 5.5}" width="16" height="11"/>'
                  f'<path class="bm" d="M{cx - 8} {cy - 5.5} L{cx} {cy + 1} L{cx + 8} {cy - 5.5}"/>')
    return shape + text_block(cx, y + h + 16, label, "nl", 16)


def build(spec):
    pools, nodes, width, height = layout(spec)
    i = spec["id"]
    out = [f'<svg class="bpmn" viewBox="0 0 {width:.0f} {height:.0f}" style="max-width:{width:.0f}px" '
           f'role="img" aria-label="{escape(spec.get("title", "BPMN"))}">',
           '<defs>'
           f'<marker id="{i}-seq" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto">'
           '<path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>'
           f'<marker id="{i}-msg" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto">'
           '<path d="M0 0 L10 5 L0 10 z" style="fill:var(--bg)" stroke="currentColor"/></marker>'
           f'<marker id="{i}-dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7">'
           '<circle cx="5" cy="5" r="4" style="fill:var(--bg)" stroke="currentColor"/></marker>'
           '</defs>']
    for p in pools.values():
        x, y, w, h = p["box"]
        out.append(f'<rect class="bp" x="{x}" y="{y}" width="{w}" height="{h}"/>'
                   f'<line class="bp" x1="{x + POOL_LABEL}" y1="{y}" x2="{x + POOL_LABEL}" y2="{y + h}"/>'
                   + pool_label(x + POOL_LABEL / 2, y + h / 2, h, p["name"]))
    labels = []
    for f in spec["flows"]:
        kind, pts = route(f, nodes, pools)
        d = "M" + " L".join(f"{px:.0f} {py:.0f}" for px, py in pts)
        if kind == "seq":
            out.append(f'<path class="fs" d="{d}" marker-end="url(#{i}-seq)"/>')
        else:
            out.append(f'<path class="fm" d="{d}" marker-start="url(#{i}-dot)" marker-end="url(#{i}-msg)"/>')
        if f.get("label"):
            labels.append(flow_label(pts, f["label"]))
    out += [node_svg(n) for n in nodes.values()]
    out += labels
    out.append('</svg>')
    return "".join(out)


STYLE = """.bpmn { display:block; margin:0 auto; width:100%; height:auto; color:var(--ink); font:13px Inter,system-ui,sans-serif; }
.bpmn text { fill:currentColor; }
.bpmn .bp { fill:none; stroke:currentColor; stroke-opacity:.45; }
.bpmn .pl { font-weight:600; }
.bpmn .bt { fill:var(--panel); stroke:currentColor; stroke-width:1.5; }
.bpmn .be, .bpmn .bg { fill:var(--panel); stroke:currentColor; stroke-width:1.5; }
.bpmn .be-end { stroke-width:4; }
.bpmn .bx, .bpmn .bm { fill:none; stroke:currentColor; stroke-width:2.5; }
.bpmn .bm { stroke-width:1.2; }
.bpmn .fs { fill:none; stroke:currentColor; stroke-width:1.5; }
.bpmn .fm { fill:none; stroke:currentColor; stroke-width:1.2; stroke-dasharray:6 4; }
.bpmn .nl, .bpmn .fl { font-size:11px; }
.bpmn .sm { font-size:10px; font-weight:600; }
.bpmn .st-new .bt, .bpmn .st-new .be, .bpmn .st-new .bg { stroke:var(--add); fill:var(--add-soft); }
.bpmn .st-new .sm { fill:var(--add); }
.bpmn .st-changed .bt, .bpmn .st-changed .be, .bpmn .st-changed .bg { stroke:var(--chg); fill:var(--chg-soft); }
.bpmn .st-changed .sm { fill:var(--chg); }
.bpmn .st-removed .bt, .bpmn .st-removed .be, .bpmn .st-removed .bg { stroke:var(--del); fill:var(--del-soft); stroke-dasharray:5 4; }
.bpmn .st-removed .sm { fill:var(--del); }
.bpmn .fl { paint-order:stroke; stroke:var(--bg); stroke-width:4px; stroke-linejoin:round; }"""


def main():
    if sys.argv[1:] == ["--css"]:
        print(STYLE)
        return
    spec = json.load(open(sys.argv[1]) if len(sys.argv) > 1 else sys.stdin)
    print(build(spec))


if __name__ == "__main__":
    main()
