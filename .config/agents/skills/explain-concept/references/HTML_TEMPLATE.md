# HTML template

Skeleton for the concept explainer. Copy it, keep the structure and the CSS contracts, replace
everything in `«»`. Delete the diagram families and the stepper if you don't use them — but
reuse what you keep rather than inventing new visuals per section.

No MathJax, no KaTeX: they are CDN loads and the page must be self-contained. Use the `.eq`,
`.frac`, and `.math` helpers below with Unicode symbols, and never bare `$…$`.

For charts, node-link graphs, sliders, proof walks, and stepped figures, see
[VISUALIZATIONS.md](VISUALIZATIONS.md): it carries the `Viz` CSS and JS blocks to paste in at
the marked points, the interaction patterns, and the rule on which subjects **must** carry an
interactive figure. Each figure belongs immediately after the paragraph it explains — the
mounts below are placed that way on purpose; move them with their text, don't pool them.

The quiz engine below satisfies `QUIZ_RULES.md` mechanically (seeded per-question shuffle,
feedback hidden until click, no correctness leaked into the DOM). Fill `QUIZ` with your five
questions and leave the engine alone.

```html
<!doctype html>
<html lang="«en|ru»">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>«Title»</title>
<style>
  :root {
    --bg:#fbfbfa; --fg:#1f2328; --muted:#5b6470; --line:#e2e4e8;
    --card:#ffffff; --accent:#3b6db5; --accent-soft:#eaf1fb;
    --ok:#1f7a45; --ok-soft:#e7f4ec; --bad:#a13a3a; --bad-soft:#fbecec;
    --code-bg:#f4f5f7;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg:#191b1f; --fg:#e4e6ea; --muted:#a0a7b2; --line:#31353b;
      --card:#21242a; --accent:#7aa7e6; --accent-soft:#23303f;
      --ok:#6cc38c; --ok-soft:#1e3327; --bad:#e08a8a; --bad-soft:#3a2525;
      --code-bg:#1c1f24;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin:0; padding:2rem 1rem 6rem; background:var(--bg); color:var(--fg);
    font:16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  main { max-width: 46rem; margin: 0 auto; }
  h1 { font-size:1.9rem; line-height:1.25; margin:0 0 .4rem; }
  h2 { font-size:1.35rem; margin:2.6rem 0 .8rem; padding-top:.6rem; border-top:1px solid var(--line); }
  h3 { font-size:1.05rem; margin:1.6rem 0 .5rem; }
  p, li { overflow-wrap:break-word; }
  a { color:var(--accent); }
  .sub { color:var(--muted); margin:0 0 1.5rem; }
  .toc { background:var(--card); border:1px solid var(--line); border-radius:10px; padding:.9rem 1.2rem; }
  .toc ol { margin:.3rem 0 0; padding-left:1.2rem; }

  /* Code — the white-space rule is mandatory, do not remove it. */
  pre { white-space: pre; overflow-x:auto; background:var(--code-bg); border:1px solid var(--line);
        border-radius:8px; padding:.85rem 1rem; font-size:.85rem; line-height:1.5; }
  code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
  p code, li code, td code { background:var(--code-bg); padding:.1rem .3rem; border-radius:4px; font-size:.9em; }
  .fileref { color:var(--muted); font-size:.8rem; display:block; margin:-.4rem 0 .5rem; }

  /* Syntax highlighting — painted by the Hl block below. Hue carries the role, weight and
     italics carry it a second time, so the listing still reads on a monochrome screen. */
  .hl-com { color:var(--muted); font-style:italic; }
  .hl-str { color:#1f7a45; }
  .hl-num { color:#a1622a; }
  .hl-kw  { color:#7a3b9b; font-weight:600; }
  .hl-typ { color:#3b6db5; }
  .hl-fn  { color:#1f2328; font-weight:600; }
  @media (prefers-color-scheme: dark) {
    .hl-str { color:#6cc38c; }
    .hl-num { color:#d79a63; }
    .hl-kw  { color:#b98bd6; }
    .hl-typ { color:#7aa7e6; }
    .hl-fn  { color:#e4e6ea; }
  }

  /* Literate listing — prose, chunk, consequence. Chunks stay small; the assembled
     listing lives in a <details> at the end of the walkthrough. */
  .lit { border-left:2px solid var(--line); padding-left:1rem; margin:1.4rem 0; }
  .lit > pre { margin:.5rem 0; }
  .lit .lit-why { margin:.9rem 0 .1rem; }
  .lit .lit-why::before { content:"→ "; color:var(--accent); font-weight:700; }
  .lit .lit-then { margin:.15rem 0 .9rem; color:var(--muted); font-size:.9rem; }
  .lit > :first-child { margin-top:0; }
  .lit > :last-child { margin-bottom:0; }

  /* Callouts */
  .callout { border-left:3px solid var(--accent); background:var(--accent-soft);
             padding:.75rem 1rem; border-radius:0 8px 8px 0; margin:1.2rem 0; }
  .callout .label { font-weight:600; font-size:.78rem; letter-spacing:.04em;
                    text-transform:uppercase; color:var(--muted); display:block; margin-bottom:.25rem; }
  .callout p:last-child { margin-bottom:0; }

  details { border:1px solid var(--line); border-radius:8px; padding:.6rem .9rem; margin:1.2rem 0; background:var(--card); }
  summary { cursor:pointer; font-weight:600; }

  table { border-collapse:collapse; width:100%; margin:1.2rem 0; font-size:.9rem; display:block; overflow-x:auto; }
  th, td { border:1px solid var(--line); padding:.45rem .6rem; text-align:left; vertical-align:top; }
  th { background:var(--card); }

  figure { margin:1.6rem 0; }
  figcaption { color:var(--muted); font-size:.82rem; margin-top:.5rem; }

  /* Diagram family 1 — flow */
  .flow { display:flex; flex-wrap:wrap; align-items:stretch; gap:.5rem; }
  .node { flex:1 1 8rem; min-width:7rem; background:var(--card); border:1px solid var(--line);
          border-radius:8px; padding:.6rem .7rem; }
  .node .title { font-weight:600; font-size:.9rem; }
  .node .data { font-family:ui-monospace,Menlo,monospace; font-size:.75rem; color:var(--muted); margin-top:.3rem; }
  .edge { align-self:center; color:var(--muted); font-size:.78rem; white-space:nowrap; padding:0 .1rem; }

  /* Diagram family 2 — before/after */
  .ba { display:grid; grid-template-columns:1fr 1fr; gap:.75rem; }
  .ba > div { background:var(--card); border:1px solid var(--line); border-radius:8px; padding:.7rem .9rem; }
  .ba .head { font-size:.78rem; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); margin-bottom:.4rem; }
  @media (max-width:560px) { .ba { grid-template-columns:1fr; } .flow { flex-direction:column; } }

  /* Math */
  .math { font-family: ui-serif, Georgia, "Times New Roman", serif; font-style:italic; }
  .math sub, .math sup { font-style:normal; }
  .eq { background:var(--card); border:1px solid var(--line); border-radius:8px;
        padding:.8rem 1rem; margin:1.2rem 0; text-align:center; overflow-x:auto;
        font-family: ui-serif, Georgia, "Times New Roman", serif; font-size:1.05rem; }
  .eq .tag { float:right; color:var(--muted); font-size:.8rem; font-family:inherit; font-style:normal; }
  .frac { display:inline-flex; flex-direction:column; vertical-align:middle;
          text-align:center; margin:0 .25rem; line-height:1.15; }
  .frac > span:first-child { border-bottom:1px solid currentColor; padding:0 .3rem; }
  .derivation td:last-child { color:var(--muted); font-size:.85rem; }

  /* Stepper — interactive worked example */
  .stepper { background:var(--card); border:1px solid var(--line); border-radius:10px;
             padding:.9rem 1rem; margin:1.4rem 0; }
  .stepper .controls { display:flex; gap:.5rem; align-items:center; margin-bottom:.7rem; }
  .stepper button { font:inherit; cursor:pointer; background:var(--bg); color:var(--fg);
                    border:1px solid var(--line); border-radius:6px; padding:.3rem .7rem; }
  .stepper button:focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
  .stepper button[disabled] { opacity:.45; cursor:default; }
  .stepper .counter { color:var(--muted); font-size:.85rem; }
  .stepper .stage { min-height:5.5rem; }
  .stepper .note { color:var(--muted); font-size:.88rem; margin-top:.6rem; }

  /* Proof / derivation stepper — paired with Viz.proof */
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

  /* Viz — charts and node-link graphs.
     Paste the CSS block from references/VISUALIZATIONS.md here when the page has figures,
     together with its JS block below. Delete this comment if it has none. */

  /* Quiz */
  .q { background:var(--card); border:1px solid var(--line); border-radius:10px;
       padding:1rem 1.1rem; margin:1.1rem 0; }
  .q .stem { font-weight:600; margin:0 0 .7rem; }
  .opt { display:block; width:100%; text-align:left; font:inherit; cursor:pointer;
         background:var(--bg); color:var(--fg); border:1px solid var(--line);
         border-radius:8px; padding:.55rem .75rem; margin:.35rem 0; }
  .opt:hover:not([disabled]) { border-color:var(--accent); }
  .opt:focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
  .opt[disabled] { cursor:default; }
  .opt.correct { border-color:var(--ok); background:var(--ok-soft); }
  .opt.wrong   { border-color:var(--bad); background:var(--bad-soft); }
  .opt .mark { font-weight:700; margin-right:.4rem; }
  .fb { margin-top:.7rem; padding:.6rem .8rem; border-radius:8px; font-size:.92rem; }
  .fb.ok  { background:var(--ok-soft);  border-left:3px solid var(--ok); }
  .fb.no  { background:var(--bad-soft); border-left:3px solid var(--bad); }
  .score { font-weight:600; margin-top:1.2rem; }
</style>
</head>
<body>
<main>

<h1>«Concept name»</h1>
<p class="sub">«One or two sentences: what the concept is and what problem it solves.»</p>

<nav class="toc">
  <strong>Contents</strong>
  <ol>
    <li><a href="#prereq">«Prerequisites»</a></li>
    <li><a href="#intuition">«Intuition»</a></li>
    <li><a href="#formal">«Formal treatment»</a></li>
    <li><a href="#example">«Worked example»</a></li>
    <li><a href="#misconceptions">«Common misconceptions»</a></li>
    <li><a href="#reading">«Further reading»</a></li>
    <li><a href="#quiz">«Quiz»</a></li>
  </ol>
</nav>

<h2 id="prereq">«Prerequisites»</h2>

<div class="callout">
  <span class="label">«Assumed»</span>
  <p>«What this page expects you to know already, and where it is covered in the vault.»</p>
  <p>«What this page teaches from scratch — say it plainly so nobody bails early.»</p>
</div>

<h2 id="intuition">«Intuition»</h2>

<p>«The idea before the formalism. Install the picture that makes the concept obvious.»</p>

<figure>
  <div class="flow">
    <div class="node"><div class="title">«State 0»</div><div class="data">«[1,2,3,4,5]»</div></div>
    <div class="edge">→ «operation»</div>
    <div class="node"><div class="title">«State 1»</div><div class="data">«[1,2,3,4,5]»</div></div>
  </div>
  <figcaption>«The toy instance the whole page uses. Reuse it below — do not switch examples.»</figcaption>
</figure>

<h2 id="formal">«Formal treatment»</h2>

<div class="callout">
  <span class="label">«Definition»</span>
  <p>«The precise statement. Explain every symbol on first use.»</p>
</div>

<div class="eq">
  <span class="tag">(1)</span>
  <span class="math">T(n)</span> = <span class="frac"><span>«n»</span><span>«2»</span></span>
  · log <span class="math">n</span> + O(<span class="math">α(n)</span>)
</div>

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
<p class="sub">«One line on what the argument establishes, for the reader who won't step through it.»</p>

<table class="derivation">
  <thead><tr><th>«Step»</th><th>«Justification»</th></tr></thead>
  <tbody>
    <tr><td>«expression»</td><td>«why this step is allowed»</td></tr>
    <tr><td>«expression»</td><td>«why»</td></tr>
  </tbody>
</table>

<h2 id="example">«Worked example»</h2>

<p>«The same toy instance, stepped through with the state visible at every point.»</p>

<div class="stepper" id="walk">
  <div class="controls">
    <button type="button" data-step="-1">«Назад»</button>
    <button type="button" data-step="1">«Вперёд»</button>
    <button type="button" data-play aria-pressed="false">▶</button>
    <span class="counter"></span>
  </div>
  <div class="stage"></div>
  <p class="note"></p>
</div>

<figure>
  <div class="viz-control">
    <label for="«paramId»">«Parameter»</label>
    <input type="range" id="«paramId»" min="«1»" max="«100»" value="«10»" step="«1»">
    <output for="«paramId»" id="«paramId»Out">«10»</output>
  </div>
  <div id="«chartId»"></div>
  <figcaption>«What the reader should notice as they drag — state it so the point survives
  without touching the control.»</figcaption>
</figure>

<h2 id="misconceptions">«Common misconceptions»</h2>

<div class="callout">
  <span class="label">«Не путать»</span>
  <p>«The wrong model, what it predicts, and the concrete case where that prediction fails.»</p>
</div>

<h2 id="reading">«Further reading»</h2>

<ul>
  <li>«Book, chapter and section — not a bare title»</li>
  <li>«Lecture or paper, with what specifically to read in it»</li>
</ul>

<h2 id="quiz">«Quiz»</h2>
<p>«Five questions. If you can't pass them, you don't understand the change well enough to ship it.»</p>
<div id="quiz"></div>
<p class="score" id="score" hidden></p>

<script>
/* Hl — syntax highlighting for every <pre><code> on the page. Dependency-free: one
   sticky-regex scanner, run once on load over the DOM's own text, so whatever entity escaping
   the source used is already resolved before tokenising.

   Dialect per block via a class: `lang-py` for Python/Ruby/shell, where `#` starts a comment;
   `lang-txt` to switch highlighting off for raw output or prose pseudocode. Everything else —
   Swift, JS, Go, Rust, Java, C — uses the default C-family profile. Triple-quoted Python
   strings are not special-cased; put those in a `lang-txt` block if you need them. */
var Hl = (function () {
  "use strict";

  // One union of keywords across the languages this skill writes. A keyword highlighted in a
  // language that lacks it is a cosmetic miss; a separate lexer per language is a maintenance
  // burden forever. The trade is deliberate.
  var KW = ("let|var|const|func|function|def|fn|return|if|else|elif|guard|while|for|in|do|" +
            "switch|case|default|break|continue|struct|class|enum|protocol|interface|extends|" +
            "implements|import|from|package|public|private|internal|static|mutating|inout|" +
            "throws|throw|try|catch|finally|defer|new|delete|this|self|super|nil|null|None|" +
            "true|false|True|False|and|or|not|is|as|where|typealias|type|init|deinit|lazy|" +
            "override|final|async|await|yield|lambda|pass|with|repeat|until|end|then|" +
            "void|int|float|double|char|bool|string").split("|");
  var KWRE = new RegExp("^(?:" + KW.join("|") + ")$");

  var STR = /(?:"(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*'|`(?:[^`\\]|\\.)*`)/y;
  var NUM = /(?:0[xXbB][0-9a-fA-F_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?)\b/y;
  var WRD = /[A-Za-z_$][A-Za-z0-9_$]*/y;
  var WS  = /\s+/y;

  function commentRe(lang) {
    return lang === "py" ? /#[^\n]*/y : /(?:\/\/[^\n]*|\/\*[\s\S]*?\*\/)/y;
  }

  function esc(t) {
    return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  function match(re, src, i) {
    re.lastIndex = i;
    var m = re.exec(src);
    return m && m.index === i ? m[0] : null;
  }

  function paint(src, lang) {
    var COM = commentRe(lang);
    var out = "", i = 0;

    while (i < src.length) {
      var hit, kind = null;

      if ((hit = match(COM, src, i))) { kind = "com"; }
      else if ((hit = match(STR, src, i))) { kind = "str"; }
      else if ((hit = match(NUM, src, i))) { kind = "num"; }
      else if ((hit = match(WS, src, i))) { kind = null; }
      else if ((hit = match(WRD, src, i))) {
        // one word, three possible roles: keyword, type, called function, or nothing
        var after = i + hit.length;
        if (KWRE.test(hit)) kind = "kw";
        else if (/^[A-Z]/.test(hit)) kind = "typ";
        else if (src.charAt(after) === "(") kind = "fn";
      } else {
        hit = src.charAt(i);
      }

      i += hit.length;
      out += kind ? '<span class="hl-' + kind + '">' + esc(hit) + "</span>" : esc(hit);
    }
    return out;
  }

  function all(root) {
    var blocks = (root || document).querySelectorAll("pre > code");
    Array.prototype.forEach.call(blocks, function (code) {
      var cls = code.className || "";
      if (/\blang-txt\b/.test(cls) || /\bhl-done\b/.test(cls)) return;
      var lang = /\blang-py\b/.test(cls) ? "py" : "c";
      code.innerHTML = paint(code.textContent, lang);   // textContent: escaping already resolved
      code.className = (cls ? cls + " " : "") + "hl-done";
    });
  }

  return { all: all, paint: paint };
})();
Hl.all();

// Viz: paste the JS block from references/VISUALIZATIONS.md here when the page has figures.

(function () {
  "use strict";

  // Stepper engine. Each step renders a FULL state, not a delta, so jumping in mid-sequence
  // still makes sense. `render(stage)` draws with Viz; `html` is the static fallback.
  // Mount one per stepped figure — a page normally has several, next to the text each explains.
  window.mountStepper = function (boxId, STEPS) {
    var box = document.getElementById(boxId);
    if (!box || !STEPS.length) return;

    var stage = box.querySelector(".stage");
    var note = box.querySelector(".note");
    var counter = box.querySelector(".counter");
    var back = box.querySelector('[data-step="-1"]');
    var fwd = box.querySelector('[data-step="1"]');
    var play = box.querySelector("[data-play]");
    var timer = null, at = 0;

    function render() {
      stage.innerHTML = "";
      if (STEPS[at].render) STEPS[at].render(stage);      // e.g. Viz.graph / Viz.proof
      else stage.innerHTML = STEPS[at].html;
      note.textContent = STEPS[at].note || "";
      counter.textContent = (at + 1) + " / " + STEPS.length;
      back.disabled = at === 0;
      fwd.disabled = at === STEPS.length - 1;
    }
    function stop() {
      if (timer) { clearInterval(timer); timer = null; }
      if (play) { play.setAttribute("aria-pressed", "false"); play.textContent = "▶"; }
    }
    function go(d) { stop(); at = Math.min(STEPS.length - 1, Math.max(0, at + d)); render(); }

    back.addEventListener("click", function () { go(-1); });
    fwd.addEventListener("click", function () { go(1); });
    if (play) play.addEventListener("click", function () {          // never autoplay on load
      if (timer) return stop();
      if (at === STEPS.length - 1) { at = 0; render(); }
      play.setAttribute("aria-pressed", "true");
      play.textContent = "⏸";
      timer = setInterval(function () {
        at++; render();
        if (at >= STEPS.length - 1) stop();                         // stop on arrival
      }, 1200);
    });
    render();
    // Returned so a figure can swap its STEPS — e.g. a selector comparing algorithm
    // variants over the same input. Mutate the array in place, then call reset().
    return {
      render: render,
      reset: function () { stop(); at = 0; render(); },
      goto: function (i) { stop(); at = Math.min(STEPS.length - 1, Math.max(0, i)); render(); },
      at: function () { return at; }
    };
  };
})();

(function () {
  "use strict";

  // «Proof / derivation walk» — Viz.proof re-renders the whole argument per step.
  var LINES = [
    { expr: '«<span class="math">T(n)</span> = 2T(n/2) + n»', why: '«recurrence from the split»' },
    { expr: '«= <span class="math">n</span> log <span class="math">n</span>»', why: '«master theorem, case 2»' }
  ];
  mountStepper("proofWalk", LINES.map(function (_, i) {
    return {
      render: function (stage) { Viz.proof(stage, { steps: LINES, at: i }); },
      note: LINES[i].why
    };
  }));

  // «worked example» — ALWAYS a stepper for an algorithm, one entry per operation, and
  // it steps through the same input the prose narrates. Build the steps by running the
  // real algorithm, not by hand-writing states: hand-written states drift from the code.
  function buildSteps(«variant») {
    var state = «fresh state»;
    return [«initial step»].concat(«INPUT».map(function (op) {
      «apply op to state»;
      var snapshot = «copy of state»;
      return {
        render: function (stage) {
          var t = Viz.tree(stage, { parent: snapshot, aria: "«state after » " + op });
          stage.insertAdjacentHTML("beforeend",
            '<p class="cost">«counters worth showing, e.g. depth »' + t.depth + "</p>");
        },
        note: "«what this operation did and why it matters»"
      };
    }));
  }

  var STEPS = buildSteps(«default variant»);
  var walk = mountStepper("walk", STEPS);

  // Optional but cheap: let the reader re-run the SAME input under a different variant.
  // Comparing variants on one input is what makes the improvement visible.
  var sel = document.getElementById("«variantSelect»");
  if (sel) sel.addEventListener("change", function () {
    var next = buildSteps(sel.value);
    STEPS.length = 0;
    Array.prototype.push.apply(STEPS, next);
    walk.reset();
  });
})();

(function () {
  "use strict";

  // Replace with your five questions. `answer` is the index into `options`;
  // the engine shuffles display order, so the position here is not what the reader sees.
  var SEED = «pick an integer, e.g. 20260913»;
  var QUIZ = [
    {
      stem: "«Question about behavior, causality, a contract, an edge case, or a trade-off»",
      options: [
        "«Option — a real misprediction someone could make»",
        "«Option»",
        "«Option»",
        "«Option»"
      ],
      answer: 0,
      why: [
        "«Why this option is wrong — name the misconception»",
        "«Why this option is wrong»",
        "«Why this option is wrong»",
        "«Why this option is wrong»"
      ],
      correctWhy: "«Why the right answer is right — cite the behavior or code path»"
    }
    // … four more
  ];

  function rng(seed) {                       // mulberry32 — deterministic per page
    return function () {
      seed |= 0; seed = seed + 0x6D2B79F5 | 0;
      var t = Math.imul(seed ^ seed >>> 15, 1 | seed);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  var rand = rng(SEED);
  var root = document.getElementById("quiz");
  var scoreEl = document.getElementById("score");
  var answered = 0, right = 0;

  function shuffle(a) {                                   // Fisher–Yates, seeded
    for (var i = a.length - 1; i > 0; i--) {
      var j = Math.floor(rand() * (i + 1));
      var t = a[i]; a[i] = a[j]; a[j] = t;
    }
    return a;
  }

  // Correct-answer slots are a seeded permutation of 0..3, so the first four questions
  // between them use every position exactly once. QUIZ_RULES' balance requirement is
  // satisfied by construction — you no longer hunt for a lucky SEED.
  var SLOTS = shuffle([0, 1, 2, 3]);

  QUIZ.forEach(function (q, qi) {
    var order = shuffle(q.options.map(function (_, i) { return i; })
                         .filter(function (i) { return i !== q.answer; }));
    order.splice(SLOTS[qi % 4], 0, q.answer);             // answer lands in its assigned slot

    var card = document.createElement("div");
    card.className = "q";

    var stem = document.createElement("p");
    stem.className = "stem";
    stem.textContent = (qi + 1) + ". " + q.stem;
    card.appendChild(stem);

    var fb = document.createElement("div");
    fb.className = "fb";
    fb.hidden = true;

    var buttons = {};                                     // original index -> button

    function mark(btn, glyph, cls) {
      btn.classList.add(cls);
      var m = document.createElement("span");
      m.className = "mark";
      m.textContent = glyph;                              // never color alone
      btn.prepend(m);
    }

    order.forEach(function (oi) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "opt";
      btn.textContent = q.options[oi];                    // no correctness in DOM or a11y text
      buttons[oi] = btn;
      btn.addEventListener("click", function () {
        if (!fb.hidden) return;
        var ok = oi === q.answer;
        answered++; if (ok) right++;
        Array.prototype.forEach.call(card.querySelectorAll(".opt"), function (b) {
          b.disabled = true;
        });
        if (ok) {
          mark(btn, "✓", "correct");
        } else {
          mark(btn, "✗", "wrong");
          mark(buttons[q.answer], "✓", "correct");        // show what was right
        }
        fb.className = "fb " + (ok ? "ok" : "no");
        fb.textContent = ok ? q.correctWhy : (q.why[oi] + " — " + q.correctWhy);
        fb.hidden = false;
        scoreEl.hidden = false;
        scoreEl.textContent = right + " / " + answered + " «correct so far»";
      });
      card.appendChild(btn);
    });

    card.appendChild(fb);
    root.appendChild(card);
  });
})();
</script>

</main>
</body>
</html>
```

## Before saving

- Every `«»` placeholder replaced, including `SEED`.
- Each `pre` rule still carries `white-space: pre` (or `pre-wrap`).
- No `http://`, `https://`, `src="./`, or `@import` outside prose links.
- No bare `$…$` anywhere — math is `.math` / `.eq` / `.frac` markup with Unicode symbols.
- **Money is written `USD`, never `$`.** The check is a bare-dollar regex over everything
  outside `<script>`; it cannot tell `$10k` from LaTeX and fails the page either way. Inside a
  script the sign is fine, because scripts are stripped before the check runs.
- Every `aria` string is a sentence of at least 25 characters. "chart" and "the tree" fail.
- Five entries in `QUIZ`, correct-answer positions spread across the four slots after
  shuffling, each `why[]` covering every wrong option.
- Stepper deleted if unused; if used, `STEPS` filled and the counter reads `1 / n` on load.
- Figures: the `Viz` CSS and JS blocks pasted in if any figure uses them, every chart and
  graph given a real `aria` sentence, every axis labelled with units, sliders mirrored into an
  `<output>`, no invented numbers.
- One toy instance carried through Intuition, Formal treatment, and Worked example — not
  three different examples.
- Every `<pre><code>` is highlighted: `Hl.all()` is present and runs, and a block that must
  stay plain (raw output, a data dump) says so with `class="lang-txt"` rather than being
  left unpainted by accident.
- **Run it**: `node references/verify.js "<file>.html"` must print PASS. It parses the page,
  executes every script, clicks every button, drags every slider, cycles every select, and
  fails on any thrown error, an empty figure mount, a stepper that does not start at `1 / n`,
  or quiz feedback that is visible before a click. Greps cannot tell you that `Viz.tree` threw.
