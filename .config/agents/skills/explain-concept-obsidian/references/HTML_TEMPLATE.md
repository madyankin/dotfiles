# HTML template

Skeleton for the concept explainer. Copy it, keep the structure and the CSS contracts, replace
everything in `«»`. Delete the diagram families and the stepper if you don't use them — but
reuse what you keep rather than inventing new visuals per section.

No MathJax, no KaTeX: they are CDN loads and the page must be self-contained. Use the `.eq`,
`.frac`, and `.math` helpers below with Unicode symbols, and never bare `$…$`.

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
    <span class="counter"></span>
  </div>
  <div class="stage"></div>
  <p class="note"></p>
</div>

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
(function () {
  "use strict";

  // Worked-example stepper. Each step renders into .stage; `note` explains what just happened.
  // Delete this block if the page has no stepped example.
  var STEPS = [
    { html: '«<div class=\"flow\">…</div>» — state after step 0', note: '«What to notice here»' }
    // … one entry per step
  ];

  var box = document.getElementById("walk");
  if (box && STEPS.length) {
    var stage = box.querySelector(".stage");
    var note = box.querySelector(".note");
    var counter = box.querySelector(".counter");
    var back = box.querySelector('[data-step="-1"]');
    var fwd = box.querySelector('[data-step="1"]');
    var at = 0;

    function render() {
      stage.innerHTML = STEPS[at].html;
      note.textContent = STEPS[at].note;
      counter.textContent = (at + 1) + " / " + STEPS.length;
      back.disabled = at === 0;
      fwd.disabled = at === STEPS.length - 1;
    }
    back.addEventListener("click", function () { if (at > 0) { at--; render(); } });
    fwd.addEventListener("click", function () { if (at < STEPS.length - 1) { at++; render(); } });
    render();
  }
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
- No bare `$…$` anywhere — math is `.math` / `.eq` / `.frac` markup with Unicode symbols.
- Five entries in `QUIZ`, correct-answer positions spread across the four slots after
  shuffling, each `why[]` covering every wrong option.
- Stepper deleted if unused; if used, `STEPS` filled and the counter reads `1 / n` on load.
- One toy instance carried through Intuition, Formal treatment, and Worked example — not
  three different examples.
