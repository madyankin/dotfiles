---
name: explain-diff
description: Build a rich HTML explainer of a code change, diff, branch, or pull request — interactive charts, node-link graphs, stepped traces, and a five-question quiz — and file it into the Obsidian vault with a markdown stub and Anki cards. Use when the user asks to explain, understand, or write up a diff/PR/branch/commit, or asks for an explainer note in their vault.
---

# Explain Diff → Obsidian

Turn a code change into a document that teaches it. The deliverable is two files that sit
next to each other in the vault:

- `<slug>.html` — a single self-contained page: background, intuition, code walkthrough,
  CSS diagrams, and five clickable quiz questions.
- `<slug>.md` — an Obsidian stub: frontmatter, summary, takeaways, wikilinks, and a record
  of the Anki cards that were pushed.
  This is what vault search, the graph, and mobile see.

The quiz is the point, not decoration. The working rule from the source of this idea: *don't
send code to others until you can pass the quiz on it.*

## Output location

```
<vault>/3 Resources/Explanations/YYYY-MM-DD <slug>.html
<vault>/3 Resources/Explanations/YYYY-MM-DD <slug>.md
```

Date prefix keeps the folder time-sorted. `<slug>` is short, kebab-case, English, derived
from what changed (`bidder-ttl-cache`, not `pr-4821`). Create the folder if missing.

Find the vault: `$OBSIDIAN_VAULT` if set, otherwise the `path` of the vault in
`~/Library/Application Support/obsidian/obsidian.json`:

```bash
VAULT="${OBSIDIAN_VAULT:-$(python3 -c 'import json,os;d=json.load(open(os.path.expanduser("~/Library/Application Support/obsidian/obsidian.json")));print(next(iter(d["vaults"].values()))["path"])')}"
```

The path contains spaces and lives in iCloud — quote it everywhere.

## Workflow

1. **Resolve the target.** Working-tree diff, `git diff <range>`, a branch, or `gh pr diff
   <n>`. If the user was ambiguous, pick the most likely target, proceed, and state the
   assumption in the page's summary.
2. **Investigate the system, not the patch.** Read callers, tests, config, data models, and
   the code paths on both sides of the change. Prefer checked-in tests and fixtures over
   speculation. You are explaining behavior; a file-by-file diff readout is a failure mode.
3. **Search the vault** for related notes so the stub can link into what already exists:
   `obsidian search query="…" limit=10` when Obsidian is running, otherwise
   `rg -il "<term>" "$VAULT"`.
4. **Write the narrative before the HTML.** Answer, in order: what problem forced this
   change; how the old system behaved; the smallest useful mental model of the new behavior;
   how the implementation realizes that model; what edge cases and trade-offs follow.
5. **Write the `.html`** from `references/HTML_TEMPLATE.md`.
6. **Write the `.md` stub** from `references/STUB_TEMPLATE.md`.
7. **Validate** against the checklist below. Fix, don't report around.
8. **Hand off**: absolute path of both files, a `file://` URL for the browser, and one line
   on where the quiz is interactive (see Rendering reality).

## Page structure

Title, one-paragraph summary, table of contents, then one continuous page — no top-level
tabs, no separate pages.

1. **Background** — only the system needed to follow the change. Open with a beginner mental
   model inside a collapsed `<details>` so an experienced reader can skip it, then narrow to
   the exact components, contracts, and prior behavior involved.
2. **Intuition** — the core idea before any implementation detail. Small concrete toy inputs
   and outputs. Show old versus new side by side whenever the comparison carries the point.
3. **Code** — walk the changes in conceptual groups ordered by execution or dependency flow,
   never alphabetically by filename. Cite `path/to/file.rb:42`. Quote the lines that matter;
   do not dump the diff.
4. **Quiz** — exactly five interactive multiple-choice questions. See
   `references/QUIZ_RULES.md`; those rules are binding.

Prose: plain, precise, systems-oriented. Explain jargon on first use. Smooth transitions
between sections rather than a list of headings. Callouts for definitions, invariants, edge
cases, and practical consequences.

## Figures, graphs, and interactive visualizations

Build a figure whenever it does work the prose cannot — and build it interactive whenever the
reader would otherwise have to hold several states in their head. `references/VISUALIZATIONS.md`
carries the full catalog, the `Viz` CSS/JS blocks, and the interaction patterns. Read it
before writing the page.

**Mandatory, not optional:** if the change touches an algorithm, a data structure, a proof or
complexity argument, a protocol, a state machine, or any process with steps, that part of the
page gets an interactive figure — a stepper over the real sequence, a `Viz.graph` of the
structure, a `Viz.proof` walk through the argument. A changed algorithm explained only in
prose is an unfinished explainer.

Placement is part of the rule: the figure goes **immediately after the paragraph it
illustrates**, inside that section. Never a gallery at the bottom. The stepper for a traced
request belongs in the walkthrough, stepping through the same example the walkthrough narrates.

The rest of the toolkit:

- **Charts** (`Viz.chart`, inline SVG, no library) for anything quantitative the change moves:
  latency before/after across p50/p95/p99, allocations per request, hit rate against TTL. Only
  with real numbers — a benchmark, CI timings, a dashboard the user pointed at. **Never invent
  data to get a nicer picture**; label estimates as estimates in the caption.
- **Node-link graphs** (`Viz.graph`) for structure with topology: call graphs, module
  dependencies, state machines. Mark added or removed edges and name them in the caption.
- **Sliders** when a parameter has a regime the reader should feel — drag TTL, watch hit rate
  and staleness trade off.
- **Play/pause** beside the step controls when the sequence is long enough to watch run.
- **Static families** — `.flow` for a linear pipeline, `.ba` for two states of one thing,
  tables for mappings and toy data.

Reuse a small set of families across the page; four instances of two families teach more than
eight one-offs. **Never ASCII art.** Caption every figure with what to notice, label axes with
units, and give every `Viz` call an `aria` sentence. A purely structural change — a rename, an
extracted function — gets a before/after panel and nothing more.

## Rendering reality (state this to the user on every run)

The page lives in the vault but Obsidian is not a browser:

- **Browser = full fidelity.** Quiz clicks, charts, steppers, and sliders work only here.
  Hand over the `file://` URL and say so.
- **HTML Reader plugin (`obsidian-html-plugin`) = read-only preview, and it is not installed.**
  Its own README says "almost all script codes cannot work": Text and High Restricted modes
  strip scripts, Balance (the default) sanitizes them, and only Low Restricted / Unrestricted
  execute anything. Installing it is the user's call; the skill does not require it.
- **Local images never load** inside Obsidian (`<img src="./x.png">` is blocked). Use CSS and
  SVG figures, or inline a data URI. No external images either — see the self-containment rule.
- **Figures are script-driven**, so under HTML Reader they render empty. The collapsible data
  table `Viz.chart` emits is what survives there — keep it.
- **Mobile** sees the `.md` stub, which is why the stub carries the summary and takeaways
  rather than only a link. Obsidian renders Mermaid natively, so one small Mermaid diagram in
  the stub carries the structural idea without opening the page.

## HTML constraints

- One file. Inline `<style>` and `<script>`. No CDN, no external fonts, no remote images, no
  fetch. The page must work offline and inside the vault forever.
- `<pre><code>…</code></pre>` for code. The CSS rule for `pre` **must** include
  `white-space: pre` or `white-space: pre-wrap`, or the browser collapses the listing into a
  single line. Check every block in the saved file before handing off.
- Escape code-derived text for both HTML and JS contexts.
- Keep the JavaScript small, namespaced, dependency-free, and attached with
  `addEventListener`. No inline `onclick` handlers.
- Responsive at phone width; visible focus states; correctness never conveyed by color alone.
- Palette should read well next to Obsidian's theme — support `prefers-color-scheme: dark`.

## Flashcards → Anki

After the files are written, offer to turn the quiz and takeaways into Anki cards. Card
creation is **not** this skill's job — invoke the `anki-cards` skill, which owns the Anki MCP
(`http://127.0.0.1:3141/`, tools prefixed `mcp__anki__`) and the card-quality rules.

- Deck: `Explanations::Code`. Create it if missing (`create_deck` supports `Parent::Child`).
- Tag every card with the explainer slug plus the repo, e.g. `bidder-ttl-cache`, `dsp-core`,
  so a later run can find them with `find_notes`.
- 5–10 cards drawn from the quiz and the takeaways.
- Record what was pushed in the stub's card section as plain `front → back` bullets, and put
  the deck in the stub's `anki-deck` frontmatter.

> [!warning] Never write `:::` lines into the stub.
> The `flashcards-obsidian` plugin is installed and syncs any `:::` line it finds to Anki.
> With the MCP as the single source of cards, a `:::` line means every card exists twice.
> Use `→` in the record section.

## Language

Match the user's request language — asked in Russian, write the page and the stub in Russian.
Code, identifiers, API names, and established technical terms stay English either way.

## Validation checklist

Run these before handing off:

```bash
grep -nE 'https?://|src="\./|@import' "<file>.html"   # must return nothing (links in prose are fine)
grep -n 'white-space' "<file>.html"                   # every pre rule covered
grep -n 'aria-label' "<file>.html"                    # every figure described, none says just "chart"
grep -n ':::' "<file>.md"                             # must return nothing — see Flashcards
```

- five questions, correct-answer position varied across them, feedback hidden until click,
  answers absent from DOM order, `title` attributes, and accessibility labels
- **any algorithm, data structure, protocol, or stepped process the change touches has an
  interactive figure next to the text explaining it**
- every figure: real data or a labelled estimate, axes with units, a caption saying what to
  notice, a data table left in place, controls reachable by keyboard, no autoplay
- stub frontmatter parses; the link to the `.html` resolves; every wikilink target exists;
  any Mermaid block renders
- say what you inspected and every assumption you made; never claim behavior the source does
  not support

## Files

- `references/HTML_TEMPLATE.md` — page skeleton with the CSS, the quiz engine, the stepper,
  and the static diagram families
- `references/VISUALIZATIONS.md` — when a figure is worth building, what kind to use, and the
  `Viz` chart/graph blocks with the slider and stepper patterns
- `references/STUB_TEMPLATE.md` — the markdown stub
- `references/QUIZ_RULES.md` — binding rules for writing the five questions
