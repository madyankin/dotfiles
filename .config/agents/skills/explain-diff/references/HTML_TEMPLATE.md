# Page components

`example.html` is the reference page, written in Artifact form (no document skeleton). Copy its `<title>`, font links, tokens and CSS, keep the component markup, replace the content.

For a local file instead of an Artifact, wrap it in `<!doctype html><html lang="…"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">…</head><body>…</body></html>` and add before `</body>`:

```html
<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.esm.min.mjs';
const css = getComputedStyle(document.documentElement);
const v = (name) => css.getPropertyValue(name).trim();
mermaid.initialize({ startOnLoad: true, securityLevel: 'strict', theme: 'base', themeVariables: {
  fontFamily: 'Inter, system-ui, sans-serif', primaryColor: v('--panel'), primaryTextColor: v('--ink'),
  primaryBorderColor: v('--muted'), lineColor: v('--muted'), textColor: v('--ink'),
  edgeLabelBackground: v('--surface'), clusterBkg: v('--panel'), mainBkg: v('--panel'), nodeBorder: v('--muted') } });
</script>
```

| Component | Markup in example.html | Use for |
| --- | --- | --- |
| Layout + TOC | `.layout`, `nav.toc` | Every page; TOC lists the top, the mechanisms, the reference |
| Hero | `header#top`: `.eyebrow`, `h1`, `.lead`, `.chips` | Layer 1 title, core idea, PR / commits / size |
| Context tiles | `.context` > `.ctx` (`.ctx--why`, `.ctx-label`, `.ctx-note`) | Why, terms, Example under the hero chips |
| Before / after | `.ba` > `.ba-row` (`.ba-q`, `.ba-old`, `.ba-arrow`, `.ba-new`) | 3–5 questions answered in full sentences |
| Diagram panel | `figure.fig` > `.fig-frame` + `figcaption` | Every diagram, BPMN SVG or `pre.mermaid` |
| Unchanged strip | `p.unchanged` | One line under before/after: what stays the same or is out of scope |
| Before line | `p.before` | First line of a mechanism: how this part worked before |
| Shared input | `p.input` | The shared example at this step: what goes in, what comes out |
| Proof | `p.proof`, `p.proof.proof--none` | Last line of a mechanism: the spec that covers it, or what is not covered |
| Inference badge | `span.inferred` | Next to any claim you inferred rather than read or ran |
| Mechanism cards | `.cards` > `a.card` (`.n`, `strong`, `.h`) | Links from the top to each mechanism section |
| Review risks | `details.callout#risks` > `ol.risks` | Every risk, collapsed, right after the mechanism cards |
| Section head | `.sec-head` (`.sec-num`, `h2`) | Each mechanism section |
| Code step | `.step` (`.step-head`, `pre`, `.why`) | Literate inserts; highlight with `.kw`, `.str`, `.sym` |
| Example | `.example` | Named scenario or boundary case |
| Accordion | `details.acc` + `.acc-body`, `.count` | Reference blocks |
| Tool cards | `.api-grid` > `.api`, `.pchip--add/--del/--opt`, `.badge--new/--chg` | Tools / endpoints |
| Error groups | `.err-group` > `.err-list(.ordered)` | Errors by call, in check order |
| Other changes | `.misc` > `section` | Payload, DB, session, analytics, security, agent text |

BPMN: paste the SVG from `scripts/bpmn_svg.py` into a `.fig-frame`; its CSS (`bpmn_svg.py --css`) goes into `<style>` once. Mermaid: `<pre class="mermaid">` in a `.fig-frame`, initialised by the script at the end of example.html. Escape `<`, `>`, `&` in code and Mermaid labels. Never leave a placeholder in a finished page.
