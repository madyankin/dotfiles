# HTML template

Skeleton for the explainer page. Copy it, keep the structure and the CSS contracts, replace
everything in `«»`. Delete the diagram families you don't use — but reuse the ones you keep
rather than inventing new visuals per section.

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

<h1>«Title: what changed, in one line»</h1>
<p class="sub">«One or two sentences: the change, the repo, the source (PR #, branch, commit range), the date.»</p>

<nav class="toc">
  <strong>Contents</strong>
  <ol>
    <li><a href="#background">«Background»</a></li>
    <li><a href="#intuition">«Intuition»</a></li>
    <li><a href="#code">«Code»</a></li>
    <li><a href="#quiz">«Quiz»</a></li>
  </ol>
</nav>

<h2 id="background">«Background»</h2>

<details>
  <summary>«New to this subsystem? Start here» — skip if you already know «X»</summary>
  <p>«Beginner mental model. Plain language, no assumed vocabulary.»</p>
</details>

<p>«The narrow background: exactly the components, contracts, and prior behavior the change touches.»</p>

<div class="callout">
  <span class="label">Definition</span>
  <p>«Term the rest of the page leans on.»</p>
</div>

<figure>
  <div class="flow">
    <div class="node"><div class="title">«Client»</div><div class="data">«{id: 42}»</div></div>
    <div class="edge">→ «HTTP POST»</div>
    <div class="node"><div class="title">«Service»</div><div class="data">«lookup(42)»</div></div>
    <div class="edge">→ «miss»</div>
    <div class="node"><div class="title">«Store»</div><div class="data">«nil»</div></div>
  </div>
  <figcaption>«What the path looked like before the change, with real values on the wire.»</figcaption>
</figure>

<h2 id="intuition">«Intuition»</h2>

<p>«The core idea in prose, before any implementation detail. Use one toy example and carry it through.»</p>

<figure>
  <div class="ba">
    <div><div class="head">Before</div><p>«Behavior with the toy input.»</p></div>
    <div><div class="head">After</div><p>«Behavior with the same toy input.»</p></div>
  </div>
  <figcaption>«Same input, both sides. State the observable difference in one sentence.»</figcaption>
</figure>

<h2 id="code">«Code»</h2>

<h3>«Group 1 — ordered by execution flow, not filename»</h3>
<span class="fileref">«path/to/file.rb:42-58»</span>
<pre><code>«the lines that matter, not the whole diff»</code></pre>
<p>«Why this shape, and what it guarantees.»</p>

<div class="callout">
  <span class="label">Edge case</span>
  <p>«The case a reader would get wrong.»</p>
</div>

<h2 id="quiz">«Quiz»</h2>
<p>«Five questions. If you can't pass them, you don't understand the change well enough to ship it.»</p>
<div id="quiz"></div>
<p class="score" id="score" hidden></p>

<script>
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

  QUIZ.forEach(function (q, qi) {
    var order = q.options.map(function (_, i) { return i; });
    for (var i = order.length - 1; i > 0; i--) {          // Fisher–Yates, seeded
      var j = Math.floor(rand() * (i + 1));
      var t = order[i]; order[i] = order[j]; order[j] = t;
    }

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
- Five entries in `QUIZ`, correct-answer positions spread across the four slots after
  shuffling, each `why[]` covering every wrong option.
