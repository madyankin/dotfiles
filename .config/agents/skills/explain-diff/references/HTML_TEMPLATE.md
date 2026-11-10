# Static HTML starting point

Adapt or remove sections to fit the change. Replace every «placeholder» with verified facts. The snippets below are a layout example, **not** source code for the change. Keep the same input in both flowcharts and the table. Use real, line-linked excerpts in the code section. No script is required.

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
    @media (max-width:700px) {
      body { padding:1rem; }
      .comparison,.code-row { grid-template-columns:1fr; }
    }
  </style>
</head>
<body>
  <header>
    <h1>«Change title»</h1>
    <p>«One-sentence behavioral summary.»</p>
    <p class="meta">«base SHA» → «head SHA» · «comparison scope»</p>
  </header>

  <main>
    <h2>Before → After</h2>
    <figure>
      <div class="comparison">
        <section class="panel" aria-label="Before change">
          <h3>Before</h3>
          <ol class="flow">
            <li>Input: «the shared example»</li>
            <li>«Old step»</li>
            <li class="changed">«Old decision or action»
              <ul class="branches">
                <li><strong>If «condition»</strong>«outcome A»</li>
                <li><strong>Otherwise</strong>«outcome B»</li>
              </ul>
            </li>
            <li>Output / side effect: «old result for the shared input»</li>
          </ol>
        </section>
        <section class="panel" aria-label="After change">
          <h3>After</h3>
          <ol class="flow">
            <li>Input: «the same example»</li>
            <li>«New step»</li>
            <li class="changed">«New decision or action»
              <ul class="branches">
                <li><strong>If «condition»</strong>«outcome A»</li>
                <li><strong>Otherwise</strong>«outcome B»</li>
              </ul>
            </li>
            <li>Output / side effect: «new result for the shared input»</li>
          </ol>
        </section>
      </div>
      <figcaption>«One observation the reader should notice; identify the changed step.»</figcaption>
    </figure>

    <h2>Same input, different result</h2>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Input</th><th>Before</th><th>After</th><th>Evidence</th></tr></thead>
        <tbody><tr><td>«shared input»</td><td>«old output»</td>
          <td>«new output»</td><td>«test or code citation»</td></tr></tbody>
      </table>
    </div>

    <h2>Code in context</h2>
    <h3>«One step in execution order»</h3>
    <div class="comparison">
      <div>
        <p>Before · <a href="«old SHA permalink with #Lx-Ly»">«path:lines»</a></p>
        <div class="code-row">
          <pre><code>«escaped real old code»</code></pre>
          <p class="explain">«What these lines did for the shared input.»</p>
        </div>
      </div>
      <div>
        <p>After · <a href="«new SHA permalink with #Lx-Ly»">«path:lines»</a></p>
        <div class="code-row">
          <pre><code>«escaped real new code»</code></pre>
          <p class="explain">«What changed and why the output differs.»</p>
        </div>
      </div>
    </div>

    <details>
      <summary>Background, boundaries, and investigation</summary>
      <p>«Only context that supports the explanation, plus caveats and sources.»</p>
    </details>
  </main>
</body>
</html>
```

For a structural change with no meaningful branch, remove the branch lists. For a longer path, add verified steps; avoid empty boxes. Never leave a placeholder, fictitious citation, or code sample in a finished page.
