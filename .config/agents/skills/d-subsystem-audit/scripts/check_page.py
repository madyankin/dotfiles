#!/usr/bin/env python3
"""Render an artifact page in both themes and check what a reader actually sees.

    python3 -I check_page.py <page.html> [--width 1300] [--out DIR]

Runs headless Chrome in Docker (zenika/alpine-chrome:124) once per theme. For every
visible text node, HTML and SVG, it compares the computed text colour with the
colour actually behind it (WCAG ratio; 4.5 for body text, 3 for large). For SVG
labels it also checks the text stays inside the shape it sits on. Token math
misses both: an SVG <text> with no fill renders black in the dark theme.

Writes <out>/light.png and <out>/dark.png (full page) and prints every failure.
Exit 0 = both themes pass, 1 = failures, 2 = could not render.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

IMAGE = "zenika/alpine-chrome:124"
MAX_HEIGHT = 16000

CHECKER = r"""
<script>
(() => {
  const parse = s => {
    const m = /rgba?\(([^)]+)\)/.exec(s || '');
    if (!m) return null;
    const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number);
    return {r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1};
  };
  const over = (top, under) => {
    const a = top.a;
    return {r: top.r * a + under.r * (1 - a), g: top.g * a + under.g * (1 - a), b: top.b * a + under.b * (1 - a), a: 1};
  };
  const lum = c => [c.r, c.g, c.b].map(v => v / 255)
    .map(v => v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4)
    .reduce((s, v, i) => s + v * [0.2126, 0.7152, 0.0722][i], 0);
  const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
  const hex = c => '#' + [c.r, c.g, c.b].map(v => Math.round(v).toString(16).padStart(2, '0')).join('');

  // Background behind an HTML element: composite non-transparent backgrounds up the tree.
  const htmlBg = el => {
    const layers = [];
    for (let n = el; n && n.nodeType === 1; n = n.parentElement) {
      const c = parse(getComputedStyle(n).backgroundColor);
      if (c && c.a > 0) { layers.push(c); if (c.a >= 1) break; }
    }
    let bg = {r: 255, g: 255, b: 255, a: 1};
    for (let i = layers.length - 1; i >= 0; i--) bg = over(layers[i], bg);
    return bg;
  };
  const SHAPES = 'rect,path,circle,ellipse,polygon';
  const inside = (r, s) => { const x = r.left + r.width / 2, y = r.top + r.height / 2;
    return x >= s.left && x <= s.right && y >= s.top && y <= s.bottom; };
  // Topmost filled shape painted before the text whose box holds the text's centre.
  const svgShape = t => {
    const svg = t.ownerSVGElement; if (!svg) return null;
    const r = t.getBoundingClientRect(); let hit = null;
    for (const s of svg.querySelectorAll(SHAPES)) {
      if (s.closest('defs,marker,clipPath,mask')) continue;
      if (!(s.compareDocumentPosition(t) & Node.DOCUMENT_POSITION_FOLLOWING)) continue;
      const f = parse(getComputedStyle(s).fill);
      if (!f || f.a === 0) continue;
      const b = s.getBoundingClientRect();
      if (b.width < 2 || b.height < 2 || !inside(r, b)) continue;
      hit = {el: s, fill: f, box: b};
    }
    return hit;
  };
  const label = el => (el.id ? '#' + el.id : el.tagName.toLowerCase()) +
    (el.closest('[data-id]') ? '[' + el.closest('[data-id]').dataset.id + ']' : '');

  const run = () => {
    const fails = [], overflow = [], seen = new Set(); let checked = 0;
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    for (let n; (n = walker.nextNode());) {
      const text = n.textContent.trim(); if (!text) continue;
      const el = n.parentElement;
      if (!el || el.closest('script,style,title,noscript,[hidden],defs')) continue;
      const box = el.getBoundingClientRect(), cs = getComputedStyle(el);
      if (box.width === 0 || box.height === 0 || cs.visibility === 'hidden' || +cs.opacity === 0) continue;
      const isSvg = el instanceof SVGElement;
      const t = isSvg ? (el.closest('text') || el) : el;
      let fg = parse(isSvg ? getComputedStyle(t).fill : cs.color);
      if (!fg) continue;
      let bg, shape = null;
      if (isSvg) { shape = svgShape(t); bg = shape ? over(shape.fill, htmlBg(t.ownerSVGElement)) : htmlBg(t.ownerSVGElement); }
      else bg = htmlBg(el);
      fg = over(fg, bg);
      const size = parseFloat(cs.fontSize), bold = parseInt(cs.fontWeight) >= 700;
      const need = size >= 24 || (size >= 18.66 && bold) ? 3 : 4.5;
      const r = ratio(fg, bg); checked++;
      const key = hex(fg) + hex(bg) + text.slice(0, 40);
      if (r < need && !seen.has(key)) { seen.add(key);
        fails.push({where: label(t), text: text.slice(0, 50), fg: hex(fg), bg: hex(bg), ratio: +r.toFixed(2), need}); }
      if (isSvg && shape && t.tagName === 'text') {
        const tb = t.getBoundingClientRect(), sb = shape.box;
        const spill = Math.max(sb.left - tb.left, tb.right - sb.right);
        if (spill > 1 && !seen.has('o' + text)) { seen.add('o' + text);
          overflow.push({where: label(t), text: text.slice(0, 50), spill_px: Math.round(spill)}); }
      }
    }
    const pre = document.createElement('pre'); pre.id = '__page_check'; pre.hidden = true;
    pre.textContent = JSON.stringify({height: document.documentElement.scrollHeight, checked, fails, overflow});
    document.body.appendChild(pre);
  };
  addEventListener('load', () => document.fonts.ready.then(() => setTimeout(run, 300)));
})();
</script>
"""


def variant(html, theme, checker):
    head = f'<script>document.documentElement.dataset.theme="{theme}"</script>'
    body = html + (CHECKER if checker else "")
    return head + body


def chrome(out, theme, args):
    flags = ["--no-sandbox", "--hide-scrollbars", "--virtual-time-budget=10000"]
    if theme == "dark":
        flags.append("--force-dark-mode")
    cmd = ["docker", "run", "--rm", "-v", f"{out}:/w", IMAGE, *flags, *args]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=180)


def check(page, out, width):
    html = page.read_text(encoding="utf-8")
    results = {}
    for theme in ("light", "dark"):
        (out / f"{theme}-check.html").write_text(variant(html, theme, True), encoding="utf-8")
        (out / f"{theme}.html").write_text(variant(html, theme, False), encoding="utf-8")
        p = chrome(out, theme, [f"--window-size={width},1000", "--dump-dom", f"file:///w/{theme}-check.html"])
        m = re.search(r'<pre id="__page_check" hidden="">(.*?)</pre>', p.stdout, re.S)
        if not m:
            print(f"{theme}: checker did not report (chrome exit {p.returncode})\n{p.stderr[-600:]}", file=sys.stderr)
            return None
        data = json.loads(m.group(1).replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">"))
        height = min(max(int(data["height"]), 600), MAX_HEIGHT)
        chrome(out, theme, [f"--window-size={width},{height}", f"--screenshot=/w/{theme}.png", f"file:///w/{theme}.html"])
        results[theme] = data
    return results


def report(results, out):
    bad = 0
    for theme, d in results.items():
        bad += len(d["fails"]) + len(d["overflow"])
        print(f"{theme}: {d['checked']} text nodes, {len(d['fails'])} low contrast, {len(d['overflow'])} overflow  -> {out / (theme + '.png')}")
        for f in d["fails"]:
            print(f"  CONTRAST {f['ratio']:>5} < {f['need']}  {f['fg']} on {f['bg']}  {f['where']}  \"{f['text']}\"")
        for o in d["overflow"]:
            print(f"  OVERFLOW +{o['spill_px']}px  {o['where']}  \"{o['text']}\"")
    print("PASS" if bad == 0 else f"FAIL: {bad} problems. Look at both screenshots before you say it is fixed.")
    return 0 if bad == 0 else 1


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("page", type=Path)
    ap.add_argument("--width", type=int, default=1300)
    ap.add_argument("--out", type=Path, help="default: <page stem>-check/ next to the page")
    a = ap.parse_args(argv)
    page = a.page.resolve()
    out = (a.out or page.with_name(page.stem + "-check")).resolve()
    out.mkdir(parents=True, exist_ok=True)
    results = check(page, out, a.width)
    if results is None:
        return 2
    return report(results, out)


if __name__ == "__main__":
    sys.exit(main())
