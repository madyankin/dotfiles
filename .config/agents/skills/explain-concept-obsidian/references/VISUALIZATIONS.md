# Visualizations

Graphs, charts, and interactive figures for the HTML page. The goal is understanding you
can't get from prose — not ornament.

## The rule: these subjects always get an interactive figure

Prose alone is not an acceptable explanation for anything with **state that changes, structure
that connects, or a quantity that varies**. For the subjects below, an interactive figure is
required, not optional:

| Subject | Required figure |
|---|---|
| Algorithm | Stepper over the real input, one panel per operation, state fully drawn |
| Data structure | `Viz.graph` of the structure, redrawn per operation inside the stepper |
| Proof or derivation | `Viz.proof` stepper — one line at a time, each with its justification |
| Complexity or growth claim | `Viz.chart` line plot of the competing bounds, crossover marked |
| Physical process | Parameter slider over the governing equation + chart or diagram, with play |
| Protocol, state machine, lifecycle | `Viz.graph` stepped through the transitions |
| Anything with a regime or threshold | Slider the reader can push past the threshold |

"I described it clearly in the text" does not discharge this. The figure is not a summary of
the prose — it is the part of the explanation the prose cannot carry.

The only legitimate reasons to skip: the subject has no state, no structure, and no varying
quantity (a naming convention, a definition with no mechanism); or the honest data does not
exist and inventing it would be a lie. If you skip, **say why in the page**, in one sentence,
where the figure would have been.

## Placement: next to the text it explains

A figure goes **immediately after the paragraph it illustrates**, inside that section. Never
collect figures into a gallery at the end, never push them into an appendix, never make the
reader scroll away from the sentence to find the picture that explains it.

Concretely:

- Each section that explains a mechanism carries its own figure. A page with four such
  sections has four figures, not one big one at the bottom.
- The figure and the paragraph form a unit: the paragraph says what to look for, the caption
  says what to notice, the figure lets the reader check it themselves.
- If a single figure serves three sections, it is in the wrong place — split it, or re-render
  the same family with the state each section is about.
- The stepper for an algorithm belongs in the walkthrough, stepping through exactly the
  example the walkthrough narrates. Not a different example.

## Never fake it

**Never fabricate data to get a nicer picture.** If the numbers are estimates, label them as
estimates in the caption; if they come from a benchmark or a source, cite it. Plot the actual
function, or real measurements, or nothing.

## What to use for what

| Job | Build |
|---|---|
| Trend, growth, comparison over a range | `Viz.chart` line |
| Discrete comparison across categories (p50/p95/p99, before/after) | `Viz.chart` bar |
| Correlation, spread, individual measurements | `Viz.chart` scatter |
| Trees, pointer structures, graphs, module dependencies | `Viz.graph` |
| Proof, derivation, complexity argument | `Viz.proof` inside a stepper |
| Pipeline, request path, message order | `.flow` HTML diagram |
| Two states of the same thing | `.ba` before/after panels |
| State evolving over discrete steps | `.stepper` |
| A parameter the reader should vary | `.viz-control` range input + redraw |
| Mapping, invariant, small table of values | plain `<table>` |

Reuse a small set across the page. Four instances of two families teach better than eight
one-off visuals.

## Fits for a concept explainer

- **Complexity growth** — line chart comparing the naive and improved bounds over n. Plot the
  actual functions, label the crossover, and say in the caption where the reader's real inputs
  sit on that axis.
- **Data structure state** — `Viz.graph` for the forest, tree, or heap, redrawn per step in the
  stepper. This is the single highest-value figure for an algorithms note: the worked example
  becomes something you watch rather than parse.
- **Amortized behavior** — bar or line chart of per-operation cost across a sequence, showing
  the expensive operation and the cheap ones it pays for.
- **Parameter regimes** — a slider over load factor, branching factor, page size, learning
  rate, or initial velocity, with the chart redrawn per value. The feel of the regime change
  is the thing prose cannot deliver.
- **Distributions and measurements** — scatter for data with spread; never a line through
  points that aren't a function.
- **Mechanisms with topology** — page-table walk, state machine, protocol handshake, forces on
  a body: `Viz.graph` or `.flow`, stepped if the order matters.
- **Derivations** — the two-column table stays the right tool. A derivation is not a chart.

Physics and math notes often want one plot of the governing function plus one stepped diagram
of the setup. That pair covers most concepts; resist adding a third.

## Interactive patterns

All of them are plain DOM and a few lines of JS — no library, no build step.

### Parameter slider driving a chart

```html
<figure>
  <div class="viz-control">
    <label for="load">«Load factor»</label>
    <input type="range" id="load" min="10" max="95" value="70" step="5">
    <output for="load" id="loadOut">0.70</output>
  </div>
  <div id="probeChart"></div>
  <figcaption>«What the reader should notice as they drag.»</figcaption>
</figure>

<script>
(function () {
  var slider = document.getElementById("load");
  var out = document.getElementById("loadOut");
  var mount = document.getElementById("probeChart");

  function redraw() {
    var a = slider.value / 100;
    out.textContent = a.toFixed(2);
    mount.innerHTML = "";                          // cheap and correct at this size
    Viz.chart(mount, {
      type: "line",
      xLabel: "«n»", yLabel: "«probes»",
      aria: "«probes versus n at load factor »" + a.toFixed(2),
      series: [{ name: "«expected probes»", points: «points computed from a» }]
    });
  }
  slider.addEventListener("input", redraw);
  redraw();
})();
</script>
```

Range inputs are keyboard-operable for free. Always mirror the value into an `<output>` so the
current setting is readable, and put the takeaway in the caption — the reader who never drags
still gets the point.

### Stepper over a worked example

Use the `.stepper` block from the template. Each step renders a full state, not a delta, so
jumping in mid-sequence still makes sense. Pair it with `Viz.graph` when the state is a
structure:

```js
var STEPS = [
  { render: function (stage) {
      Viz.graph(stage, { nodes: «…», edges: «…», aria: "«state after union(4,3)»" });
    },
    note: "«What just happened and why it matters»" }
];
```

### Proof and derivation stepper

Every proof, derivation, or complexity argument is stepped. The reader advances one line at a
time and sees the justification for that line; future lines are dimmed and `aria-hidden` so
the argument is not spoiled.

```html
<div class="stepper" id="proofWalk">
  <div class="controls">
    <button type="button" data-step="-1">«Назад»</button>
    <button type="button" data-step="1">«Вперёд»</button>
    <button type="button" data-play aria-pressed="false">▶</button>
    <span class="counter"></span>
  </div>
  <div class="stage"></div>
  <p class="note"></p>
</div>
```

```js
var LINES = [
  { expr: '«<span class=\"math\">T(n)</span> = 2T(n/2) + n»', why: '«recurrence from the split»' },
  { expr: '«= <span class=\"math\">n</span> log <span class=\"math\">n</span>»', why: '«master theorem, case 2»' }
];
var STEPS = LINES.map(function (_, i) {
  return {
    render: function (stage) { Viz.proof(stage, { steps: LINES, at: i }); },
    note: LINES[i].why
  };
});
```

The point is that the reader can stop at the step they don't believe and stare at it. A static
block of algebra hides exactly that step.

### Play / pause for a process

Physical processes and long operation sequences get a play button beside the step controls, so
the reader can watch it run and then scrub back to the moment that surprised them:

```js
    var play = box.querySelector("[data-play]");
    var timer = null;

    function stop() {
      if (timer) { clearInterval(timer); timer = null; }
      if (play) { play.setAttribute("aria-pressed", "false"); play.textContent = "▶"; }
    }
    function go(d) { stop(); at = Math.min(STEPS.length - 1, Math.max(0, at + d)); render(); }

    back.addEventListener("click", function () { go(-1); });
    fwd.addEventListener("click", function () { go(1); });
    if (play) play.addEventListener("click", function () {
      if (timer) return stop();
      if (at === STEPS.length - 1) { at = 0; render(); }       // replay from the start
      play.setAttribute("aria-pressed", "true");
      play.textContent = "⏸";
      timer = setInterval(function () {
        at++; render();
        if (at >= STEPS.length - 1) stop();                    // stop on arrival, not a tick later
      }, «1200»);
    });
```

Any manual control stops playback — a reader who grabs the wheel keeps it. Never autoplay on
load: motion the reader did not ask for is a distraction, and for some readers a problem.
Respect `prefers-reduced-motion` by leaving playback opt-in, which this is.

### Toggle between two states

A single button that swaps the `.ba` panels' content, or re-renders one mount with the other
dataset. Cheaper than a stepper when there are exactly two states, and it makes the
difference land physically.

## Accessibility and honesty

- Every `Viz.chart` and `Viz.graph` call takes `aria` — write a sentence that says what the
  figure shows, not "chart".
- `Viz.chart` emits a collapsible data table by default. Keep it: it is the fallback for
  screen readers, for HTML Reader's sanitized mode, and for anyone who wants the numbers.
  Pass `table: false` only when the same numbers are already in the prose.
- Series are distinguished by **dash pattern and legend glyph as well as color**. Do not
  replace that with color-only styling.
- Interactive controls must be reachable by keyboard and must have a visible focus ring — the
  template's `:focus-visible` rules cover the standard elements.
- Label axes with units. An unlabeled y-axis is a decoration.

## Obsidian reality

The charts are inline SVG driven by JS, so they live in the HTML page and render **in a
browser**. Inside Obsidian, HTML Reader sanitizes scripts and the figures will be empty — this
is the same limitation as the quiz, and the data tables are what survive.

The `.md` stub is different: Obsidian renders **Mermaid natively**, no plugin. When the note
has one structural idea worth carrying without opening the page, put a small Mermaid diagram
in the stub:

````markdown
```mermaid
flowchart LR
  A["«Client»"] -->|«miss»| B["«Cache»"]
  B --> C["«Store»"]
```
````

Keep it to one diagram and under ~10 nodes. The stub is a summary, not a second copy of the
page.

## The Viz block

Paste both blocks into the page when it has charts or node-link diagrams. The CSS goes at the
end of the `<style>` element, the JS above the other `<script>` blocks. Delete both if the
page has neither.

### CSS

```css
  /* Viz — charts and node-link graphs. Paired with the Viz JS block; delete both if unused. */
  :root { --s0:#3b6db5; --s1:#1f7a45; --s2:#a1622a; --s3:#7a3b9b; }
  @media (prefers-color-scheme: dark) {
    :root { --s0:#7aa7e6; --s1:#6cc38c; --s2:#d79a63; --s3:#b98bd6; }
  }
  .viz { display:block; width:100%; height:auto; overflow:visible; }
  .viz .grid { stroke:var(--line); stroke-width:1; }
  .viz .axis { stroke:var(--muted); stroke-width:1; }
  .viz .tick, .viz .axis-label { fill:var(--muted); font-size:11px;
        font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
  .viz .axis-label { font-size:11px; letter-spacing:.03em; }
  .viz .line { stroke-width:2; stroke-linejoin:round; stroke-linecap:round; }
  .viz .bar { opacity:.9; }
  .viz .s0 { stroke:var(--s0); } .viz rect.s0, .viz circle.s0 { fill:var(--s0); stroke:none; }
  .viz .s1 { stroke:var(--s1); } .viz rect.s1, .viz circle.s1 { fill:var(--s1); stroke:none; }
  .viz .s2 { stroke:var(--s2); } .viz rect.s2, .viz circle.s2 { fill:var(--s2); stroke:none; }
  .viz .s3 { stroke:var(--s3); } .viz rect.s3, .viz circle.s3 { fill:var(--s3); stroke:none; }
  .viz .gedge { stroke:var(--muted); stroke-width:1.5; }
  .viz .gedge.dashed { stroke-dasharray:5 3; }
  .viz .gedge-label { fill:var(--muted); font-size:11px;
        font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
  .viz .arrowhead { fill:var(--muted); }
  .viz .gnode circle { fill:var(--card); stroke:var(--accent); stroke-width:1.5; }
  .viz .gnode text { fill:var(--fg); font-size:12px;
        font-family:ui-monospace, SFMono-Regular, Menlo, monospace; }
  .viz .gnode.root circle { stroke-width:3.5; }
  .viz .gnode.muted circle { stroke:var(--muted); stroke-dasharray:3 2; }
  .viz-legend { display:flex; flex-wrap:wrap; gap:1.1rem; margin-top:.5rem;
                font-size:.82rem; color:var(--muted); }
  .viz-key.s0 { color:var(--s0); } .viz-key.s1 { color:var(--s1); }
  .viz-key.s2 { color:var(--s2); } .viz-key.s3 { color:var(--s3); }
  .viz-data { margin-top:.6rem; font-size:.85rem; }
  .viz-data summary { color:var(--muted); font-weight:400; }
  .viz-data table { margin:.5rem 0 0; }

  /* Range control for parameter-driven figures */
  .viz-control { display:flex; align-items:center; gap:.6rem; margin:.6rem 0 .2rem;
                 font-size:.88rem; flex-wrap:wrap; }
  .viz-control input[type=range] { flex:1 1 12rem; accent-color:var(--accent); }
  .viz-control output { font-family:ui-monospace, Menlo, monospace; color:var(--muted);
                        min-width:4rem; }

  /* Proof / derivation stepper */
  .proof { list-style:none; counter-reset:pf; padding:0; margin:1rem 0; }
  .proof li { counter-increment:pf; display:grid; grid-template-columns:auto 1fr;
              gap:.2rem 1rem; padding:.5rem .8rem; border-left:3px solid transparent;
              border-radius:0 6px 6px 0; }
  .proof li::before { content:"(" counter(pf) ")"; color:var(--muted); font-size:.8rem;
                      font-family:ui-monospace, Menlo, monospace; grid-row:1; }
  .proof .expr { font-family:ui-serif, Georgia, serif; font-size:1.02rem; }
  .proof .why { grid-column:2; color:var(--muted); font-size:.84rem; }
  .proof li.at { border-left-color:var(--accent); background:var(--accent-soft); }
  .proof li.next { opacity:.28; }
  .proof li.done { opacity:.85; }
```

### JS

```js
/* Viz — dependency-free SVG charts and node-link graphs. Keep as one block; delete if unused. */
var Viz = (function () {
  "use strict";
  var NS = "http://www.w3.org/2000/svg";
  var DASH = ["", "6 3", "2 3", "8 3 2 3"];          // series identity without relying on color

  function svgEl(tag, attrs) {
    var n = document.createElementNS(NS, tag);
    for (var k in attrs) if (attrs[k] != null) n.setAttribute(k, attrs[k]);
    return n;
  }
  function extent(vals) {
    var lo = Math.min.apply(null, vals), hi = Math.max.apply(null, vals);
    if (lo === hi) { lo -= 1; hi += 1; }
    return [lo, hi];
  }
  function fmt(v) {
    if (Math.abs(v) >= 1000) return (v / 1000) + "k";
    return Math.round(v * 100) / 100 + "";
  }

  /* spec: {type:"line"|"bar"|"scatter", series:[{name, points:[[x,y],…]}],
            xLabel, yLabel, height, yZero:true, xTickLabels:["a","b"], caption, table:true} */
  function chart(mount, spec) {
    var W = 640, H = spec.height || 300, P = { t: 16, r: 16, b: 42, l: 52 };
    var series = spec.series || [];
    var xs = [], ys = [];
    series.forEach(function (s) {
      s.points.forEach(function (p) { xs.push(p[0]); ys.push(p[1]); });
    });
    if (!xs.length) return;
    var xe = extent(xs), ye = extent(ys);
    if (spec.yZero !== false) ye[0] = Math.min(0, ye[0]);

    var sx = function (v) { return P.l + (v - xe[0]) / (xe[1] - xe[0]) * (W - P.l - P.r); };
    var sy = function (v) { return H - P.b - (v - ye[0]) / (ye[1] - ye[0]) * (H - P.t - P.b); };

    var svg = svgEl("svg", {
      viewBox: "0 0 " + W + " " + H, class: "viz",
      role: "img", "aria-label": spec.aria || spec.caption || "chart"
    });

    [0, 0.25, 0.5, 0.75, 1].forEach(function (f) {             // y gridlines + labels
      var v = ye[0] + f * (ye[1] - ye[0]), y = sy(v);
      svg.appendChild(svgEl("line", { x1: P.l, x2: W - P.r, y1: y, y2: y, class: "grid" }));
      var t = svgEl("text", { x: P.l - 8, y: y + 4, class: "tick", "text-anchor": "end" });
      t.textContent = fmt(v);
      svg.appendChild(t);
    });

    var ticks = spec.xTickLabels || null;
    var n = ticks ? ticks.length : 5;
    for (var i = 0; i < n; i++) {
      var f2 = n === 1 ? 0 : i / (n - 1);
      var xv = xe[0] + f2 * (xe[1] - xe[0]);
      var tx = svgEl("text", { x: sx(xv), y: H - P.b + 18, class: "tick", "text-anchor": "middle" });
      tx.textContent = ticks ? ticks[i] : fmt(xv);
      svg.appendChild(tx);
    }
    svg.appendChild(svgEl("line", { x1: P.l, x2: W - P.r, y1: sy(ye[0]), y2: sy(ye[0]), class: "axis" }));

    if (spec.yLabel) {
      var yl = svgEl("text", { x: 12, y: P.t + 4, class: "axis-label" });
      yl.textContent = spec.yLabel; svg.appendChild(yl);
    }
    if (spec.xLabel) {
      var xl = svgEl("text", { x: W - P.r, y: H - 6, class: "axis-label", "text-anchor": "end" });
      xl.textContent = spec.xLabel; svg.appendChild(xl);
    }

    series.forEach(function (s, si) {
      var cls = "s" + (si % 4);
      if (spec.type === "bar") {
        var bw = (W - P.l - P.r) / (s.points.length * series.length) * 0.7;
        s.points.forEach(function (p, pi) {
          var x = sx(p[0]) - (series.length * bw) / 2 + si * bw;
          svg.appendChild(svgEl("rect", {
            x: x, y: sy(p[1]), width: bw, height: Math.max(1, sy(ye[0]) - sy(p[1])),
            class: "bar " + cls
          }));
        });
      } else if (spec.type === "scatter") {
        s.points.forEach(function (p) {
          svg.appendChild(svgEl("circle", { cx: sx(p[0]), cy: sy(p[1]), r: 3.5, class: "dot " + cls }));
        });
      } else {
        var d = s.points.map(function (p, pi) {
          return (pi ? "L" : "M") + sx(p[0]) + " " + sy(p[1]);
        }).join(" ");
        svg.appendChild(svgEl("path", {
          d: d, class: "line " + cls, fill: "none", "stroke-dasharray": DASH[si % DASH.length]
        }));
      }
    });

    mount.appendChild(svg);

    if (series.length > 1) {                                    // legend, shape-coded not color-only
      var leg = document.createElement("div");
      leg.className = "viz-legend";
      series.forEach(function (s, si) {
        var item = document.createElement("span");
        item.className = "viz-key s" + (si % 4);
        item.textContent = (["———", "– – –", "· · ·", "–·–·"][si % 4]) + " " + s.name;
        leg.appendChild(item);
      });
      mount.appendChild(leg);
    }

    if (spec.table !== false) {                                 // data table fallback
      var det = document.createElement("details");
      det.className = "viz-data";
      var sum = document.createElement("summary");
      sum.textContent = spec.tableLabel || "Data";
      det.appendChild(sum);
      var tbl = document.createElement("table");
      var head = "<tr><th>" + (spec.xLabel || "x") + "</th>" +
        series.map(function (s) { return "<th>" + s.name + "</th>"; }).join("") + "</tr>";
      var rows = series[0].points.map(function (p, pi) {
        return "<tr><td>" + (ticks ? ticks[pi] || fmt(p[0]) : fmt(p[0])) + "</td>" +
          series.map(function (s) { return "<td>" + (s.points[pi] ? fmt(s.points[pi][1]) : "—") + "</td>"; }).join("") +
          "</tr>";
      }).join("");
      tbl.innerHTML = head + rows;
      det.appendChild(tbl);
      mount.appendChild(det);
    }
    return svg;
  }

  /* spec: {nodes:[{id,label,x,y,tag}], edges:[{from,to,label,dashed}], height} — x/y in any units */
  function graph(mount, spec) {
    var nodes = spec.nodes, edges = spec.edges || [];
    var byId = {}; nodes.forEach(function (n) { byId[n.id] = n; });
    var W = 640, H = spec.height || 300, M = 40, R = spec.radius || 18;
    var xe = extent(nodes.map(function (n) { return n.x; }));
    var ye = extent(nodes.map(function (n) { return n.y; }));
    var sx = function (v) { return M + (v - xe[0]) / (xe[1] - xe[0]) * (W - 2 * M); };
    var sy = function (v) { return M + (v - ye[0]) / (ye[1] - ye[0]) * (H - 2 * M); };

    var svg = svgEl("svg", {
      viewBox: "0 0 " + W + " " + H, class: "viz",
      role: "img", "aria-label": spec.aria || "diagram"
    });
    var defs = svgEl("defs");
    var mk = svgEl("marker", {
      id: "arrow", viewBox: "0 0 10 10", refX: 9, refY: 5,
      markerWidth: 6, markerHeight: 6, orient: "auto-start-reverse"
    });
    mk.appendChild(svgEl("path", { d: "M0 0 L10 5 L0 10 z", class: "arrowhead" }));
    defs.appendChild(mk); svg.appendChild(defs);

    edges.forEach(function (e) {
      var a = byId[e.from], b = byId[e.to];
      if (!a || !b) return;
      var x1 = sx(a.x), y1 = sy(a.y), x2 = sx(b.x), y2 = sy(b.y);
      var dx = x2 - x1, dy = y2 - y1, len = Math.sqrt(dx * dx + dy * dy) || 1;
      var ox = dx / len * R, oy = dy / len * R;
      svg.appendChild(svgEl("line", {
        x1: x1 + ox, y1: y1 + oy, x2: x2 - ox, y2: y2 - oy,
        class: "gedge" + (e.dashed ? " dashed" : ""), "marker-end": "url(#arrow)"
      }));
      if (e.label) {
        var t = svgEl("text", { x: (x1 + x2) / 2, y: (y1 + y2) / 2 - 6, class: "gedge-label", "text-anchor": "middle" });
        t.textContent = e.label; svg.appendChild(t);
      }
    });

    nodes.forEach(function (n) {
      var g = svgEl("g", { class: "gnode" + (n.tag ? " " + n.tag : "") });
      g.appendChild(svgEl("circle", { cx: sx(n.x), cy: sy(n.y), r: R }));
      var t = svgEl("text", { x: sx(n.x), y: sy(n.y) + 4, "text-anchor": "middle" });
      t.textContent = n.label;
      g.appendChild(t);
      svg.appendChild(g);
    });

    mount.appendChild(svg);
    return svg;
  }

  /* spec: {steps:[{expr, why}], at:i} — derivation or proof revealed one step at a time.
     `expr` is HTML (use the .math/.frac helpers); `why` is the justification. */
  function proof(mount, spec) {
    var at = spec.at == null ? spec.steps.length - 1 : spec.at;
    var ol = document.createElement("ol");
    ol.className = "proof";
    spec.steps.forEach(function (st, i) {
      var li = document.createElement("li");
      li.className = i < at ? "done" : (i === at ? "at" : "next");
      if (i > at) li.setAttribute("aria-hidden", "true");       // not yet revealed
      var e = document.createElement("div");
      e.className = "expr";
      e.innerHTML = st.expr;
      li.appendChild(e);
      if (st.why) {
        var w = document.createElement("div");
        w.className = "why";
        w.textContent = st.why;
        li.appendChild(w);
      }
      ol.appendChild(li);
    });
    mount.appendChild(ol);
    return ol;
  }

  return { chart: chart, graph: graph, proof: proof };
})();
```

### API

```js
Viz.chart(mountEl, {
  type: "line" | "bar" | "scatter",     // default line
  series: [{ name: "before", points: [[x, y], …] }, …],
  xLabel: "n", yLabel: "ops",
  xTickLabels: ["p50", "p95", "p99"],   // optional; categorical x
  yZero: true,                          // default true — force the y-axis to include 0
  height: 300,
  aria: "one sentence describing the figure",
  table: true,                          // default true — collapsible data table
  tableLabel: "Данные"
});

Viz.graph(mountEl, {
  nodes: [{ id: "a", label: "3", x: 0, y: 1, tag: "root" | "muted" }, …],
  edges: [{ from: "a", to: "b", label: "parent", dashed: false }, …],
  height: 300,
  radius: 18,
  aria: "one sentence describing the structure"
});

Viz.proof(mountEl, {
  steps: [{ expr: "HTML for the line", why: "justification" }, …],
  at: 2                                 // current line; later lines dimmed and aria-hidden
});
```

`Viz.graph` takes explicit `x`/`y` in any units and scales them to the viewport — compute the
layout yourself. For a tree, `x` is horizontal position within the level and `y` is the depth;
give the root the midpoint `x` of its children, or the scaling will pin it to one edge. Edges
draw an arrowhead at the `to` end; for a parent pointer, that means `{from: child, to:
parent}`. Both axes stretch to fill, so a two-node figure lands corner to corner — add the
surrounding nodes, or pad the coordinates, when that reads badly.

`Viz.proof` renders the whole argument every call and dims what is past `at`, so a stepper
re-renders it per step rather than mutating it. `expr` is HTML — use the `.math`, `.frac`, and
`<sub>`/`<sup>` helpers, never bare `$…$`.
