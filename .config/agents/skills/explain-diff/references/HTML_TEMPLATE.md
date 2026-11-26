# Static HTML starting point

Adapt to the change; numbered sections follow the page structure in SKILL.md, drop empty ones. Replace every «placeholder» with verified facts. Diagrams: inline SVG, every edge labeled in text — UML for entities, flowcharts for algorithms, BPMN for processes. Contracts as tables. No script is required.

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>«Change title»</title>
  <style>
    :root { color-scheme:dark; --bg:#111827; --panel:#1f2937; --ink:#f3f4f6;
      --muted:#cbd5e1; --line:#64748b; --accent:#93c5fd; --changed:#fbbf24; }
    @media (prefers-color-scheme:light) {
      :root { color-scheme:light; --bg:#fff; --panel:#f3f4f6; --ink:#111827;
        --muted:#374151; --line:#64748b; --accent:#1d4ed8; --changed:#92400e; }
    }
    * { box-sizing:border-box; }
    body { margin:0 auto; padding:1.5rem; max-width:76rem; background:var(--bg);
      color:var(--ink); font:1rem/1.5 system-ui,sans-serif; }
    h1,h2,h3,p,figure { margin-block:0 1rem; }
    h1 { line-height:1.2; } h2 { margin-top:2rem; }
    a { color:var(--accent); } a:focus-visible,summary:focus-visible {
      outline:2px solid var(--accent); outline-offset:3px; }
    .meta,figcaption,.note { color:var(--muted); }
    .comparison { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:1rem; }
    .panel { min-width:0; padding:1rem; border:1px solid var(--line);
      border-radius:.6rem; background:var(--panel); }
    .flow { list-style:none; margin:0; padding:0; }
    .flow > li { padding:.6rem .8rem; border:1px solid var(--line);
      border-radius:.4rem; background:var(--bg); }
    .flow > li + li { margin-top:1.6rem; position:relative; }
    .flow > li + li::before { content:"↓"; position:absolute; top:-1.55rem;
      left:50%; transform:translateX(-50%); color:var(--muted); }
    .flow .changed { border:2px solid var(--changed); }
    .branches { display:grid; grid-template-columns:repeat(2,minmax(0,1fr));
      gap:.5rem; margin:.5rem 0 0; padding:0; list-style:none; }
    .branches li { border:1px solid var(--line); border-radius:.35rem;
      padding:.45rem; font-size:.9rem; overflow-wrap:anywhere; }
    .branches strong { display:block; color:var(--accent); }
    .table-wrap { overflow-x:auto; }
    table { border-collapse:collapse; width:100%; min-width:34rem; }
    th,td { border:1px solid var(--line); padding:.55rem; text-align:left; vertical-align:top; }
    th { background:var(--panel); }
    .code-row { display:grid; grid-template-columns:minmax(0,1.4fr) minmax(12rem,1fr);
      gap:1rem; margin:1rem 0; align-items:start; }
    .code-row > * { min-width:0; }
    pre { white-space:pre; overflow-x:auto; margin:0; padding:.85rem;
      border:1px solid var(--line); border-radius:.4rem; background:var(--panel); }
    code { font: .9rem/1.45 ui-monospace,SFMono-Regular,monospace; }
    .explain { border-left:3px solid var(--accent); padding-left:.8rem; }
    details { margin:1rem 0; padding:.6rem .9rem; border:1px solid var(--line);
      border-radius:.4rem; }
    summary { cursor:pointer; font-weight:600; }
    .core { font-size:1.15rem; }
    figure svg { display:block; width:100%; height:auto; color:var(--ink); }
    figure .scroll { overflow-x:auto; }
    .step { margin:1.5rem 0; }
    .step > p:first-child strong { color:var(--accent); }
    .path { font:.85rem ui-monospace,monospace; color:var(--muted); margin:.25rem 0; }
    .risks { padding-left:1.2rem; } .risks li + li { margin-top:.8rem; }
    footer { margin-top:2.5rem; padding-top:1rem; border-top:1px solid var(--line);
      color:var(--muted); font-size:.9rem; }
    @media (max-width:700px) {
      body { padding:1rem; }
      .comparison,.code-row { grid-template-columns:1fr; }
    }
  </style>
</head>
<body>
  <header>
    <h1>«Change title»</h1>
    <p class="meta">«base SHA» → «head SHA» · «comparison scope»</p>
  </header>

  <main>
    <h2>1. What fundamentally changes</h2>
    <p class="core"><strong>«One sentence: the core idea.»</strong></p>
    <div class="table-wrap"><table>
      <thead><tr><th>Dimension</th><th>Before</th><th>After</th></tr></thead>
      <tbody><tr><td>«who decides / unit of work / protection / failure mode»</td><td>«old»</td><td>«new»</td></tr></tbody>
    </table></div>

    <h2>2. Change map</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Area</th><th>What changed</th><th>Kind</th><th>Section</th></tr></thead>
      <tbody><tr><td>«files or module»</td><td>«fragment»</td><td>«contract / entity / process / algorithm / UI / tests / config»</td><td><a href="#«id»">«section»</a></td></tr></tbody>
    </table></div>

    <h2 id="contracts">3. Contracts</h2>
    <h3>«Tools / endpoints»</h3>
    <div class="table-wrap"><table>
      <thead><tr><th>Name</th><th>Params</th><th>Returns</th><th>Errors</th><th>Status</th></tr></thead>
      <tbody><tr><td><code>«name»</code></td><td><code>«param: type, required»</code></td><td>«shape»</td><td><code>«exact error string»</code></td><td>«added / changed / removed»</td></tr></tbody>
    </table></div>
    <h3>«DB columns / payload fields / metadata keys / config»</h3>
    <div class="table-wrap"><table>
      <thead><tr><th>Field</th><th>Type, default</th><th>Meaning</th><th>Status</th></tr></thead>
      <tbody><tr><td><code>«field»</code></td><td>«type»</td><td>«fragment»</td><td>«added»</td></tr></tbody>
    </table></div>

    <h2 id="entities">4. Entities</h2>
    <figure><div class="scroll">
      <svg viewBox="0 0 «w» «h»" role="img" aria-label="«UML class diagram: X delegates to Y, persists Z»">
        <!-- UML: name / fields / methods compartments; edges labeled: delegates, persists, renders; changed elements marked in text -->
      </svg>
    </div><figcaption>«One thing to notice; shortened names.»</figcaption></figure>
    <div class="table-wrap"><table>
      <thead><tr><th>Component</th><th>Responsibility</th></tr></thead>
      <tbody><tr><td><code>«Class»</code></td><td>«one responsibility»</td></tr></tbody>
    </table></div>
    <figure><div class="scroll">
      <svg viewBox="0 0 «w» «h»" role="img" aria-label="«UML state diagram of Entity: open → applied / declined / expired»"></svg>
    </div><figcaption>«Stored or derived state; what blocks which transition.»</figcaption></figure>
    <!-- literate insert where code is the contract or order matters, see section 6 for form -->

    <h2 id="processes">5. Processes</h2>
    <figure><div class="scroll">
      <svg viewBox="0 0 «w» «h»" role="img" aria-label="«BPMN: pools Human, Agent, Client, Server, DB; message flows labeled with calls»"></svg>
    </div><figcaption>«What each party receives; where the decision happens.»</figcaption></figure>

    <h2 id="algorithms">6. Algorithms</h2>
    <h3>«Function or step, e.g. Atomic apply»</h3>
    <figure><div class="scroll">
      <svg viewBox="0 0 «w» «h»" role="img" aria-label="«flowchart: lock → token valid? → key valid? → save all → commit or rollback»"></svg>
    </div><figcaption>«The branch that matters.»</figcaption></figure>
    <section class="step">
      <p><strong>Step 1. «Intent in one sentence.»</strong></p>
      <p class="path"><a href="«SHA permalink #Lx-Ly»">«path:lines»</a></p>
      <pre><code>«escaped real code»</code></pre>
      <p>«What it makes true; why not the obvious alternative.»</p>
    </section>
    <div class="table-wrap"><table>
      <thead><tr><th>Check</th><th>What it guarantees</th></tr></thead>
      <tbody><tr><td>«check»</td><td>«guarantee»</td></tr></tbody>
    </table></div>
    <p><strong>«Named scenario»:</strong> «input → outcome».</p>

    <h2>7. Review risks</h2>
    <ol class="risks">
      <li><strong>«Risk title».</strong> «Gap and when it bites.»</li>
    </ol>

    <h2>8. Whole picture</h2>
    <figure><div class="scroll">
      <svg viewBox="0 0 «w» «h»" role="img" aria-label="«BPMN overview of the system after the change»"></svg>
    </div><figcaption>«Architectural result in one sentence.»</figcaption></figure>
  </main>
  <footer>«repo» @ «SHA». «What figures omit». «Not run: tests / clients». Risks are static analysis.</footer>
</body>
</html>
```

Literate inserts (`.step`) go under any figure whose step needs the exact code, in any section. Use the before/after `.comparison` panels only when old and new code of one step must be read side by side. Never leave a placeholder, fictitious citation, or sample code in a finished page.
