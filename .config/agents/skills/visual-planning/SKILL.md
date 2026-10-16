---
name: visual-planning
description: Turn research, a plan, or a system into a living visual page — what exists, what to build, what is missing, open decisions, options compared on one diagram, evidence with fact/inference/question marks — and keep it in sync with the markdown doc as work moves. Use when the user says "visualize what we have and what is missing", "build a map of X", "draw the plan", "compare the options visually", "mark this done in the artifact", "визуализируй", "построй карту", "что есть, что нужно сделать и чего не хватает", or wants a plan, architecture or diagnosis they can see and steer.
---

# Visual planning

A planning page is a map the user steers with. It shows where the work stands,
what blocks it, and what was decided. It lives as long as the work: every answer,
decision and merged change updates it at the same URL.

Input: finished research, a plan doc, or a system to map. Output: one page (more
only when the work splits), kept in lockstep with its markdown source.

Page recipes: `references/page-types.md`. Visual vocabulary, status names and
diagram rules: `references/visual-language.md`. Starter page with tokens, chips,
counters and filters: `assets/starter.html`.

## When to build

- Build after the evidence exists: a research doc, a plan, or code you have read.
  Never draw a map from guesses to fill a page.
- If research is missing, do it first (or run the user's research skill), then build.
- Build on an explicit ask ("visualize", "map", "draw"). When a page would help but
  nobody asked, offer it in one line.

## Steps

1. **Pick the page type** from `references/page-types.md`:
   - **Plan map** — exists / build / missing, the path in real order, decisions.
   - **System map** — state, flows, boundaries, pressure, problem register.
   - **Options** — root causes, quick fixes, one diagram with a tab per option, matrix.
   - **Evidence** — measurements or a diagnosis, verdict first.
   - **Concept explainer** — a mechanism for a newcomer, with an analogy.
   If the user names a mental model or a book chapter to follow, read it first and
   use its vocabulary and section names.

2. **Collect items with stable IDs.** Steps `S1..`, questions `Q1..`, problems
   `R1..`, quick fixes `0.1..`. The same ID appears in the doc, on the page and in
   chat. IDs never get reused or renumbered.

3. **Check every item against the source** before it goes on the page. Each gap
   must sit in the right component. Each claim gets a mark: **F** fact (seen, with a
   pointer), **I** inference (say what would refute it), **Q** open (say where to
   look). Never show an inference as a measurement.

4. **Write the page.**
   - With the Artifact tool: call `quickstart` (intent `other`), follow the
     artifact-design and artifact-diagramming rules, and the dataviz rules for charts.
   - Start from `assets/starter.html`. Write one HTML file in the session scratchpad.
   - Write in the user's language. Plain words. Define each term, flag and ID once
     on the page, with its owner and role where people are involved.
   - Without the Artifact tool: write the same HTML file and open it in a browser.

5. **Check the render before you hand it over.** Open the page in a real browser
   (built-in browser, headless Chrome). Check:
   - no duplicate `id` attributes, no script errors in the console;
   - counters match the items;
   - tables and wide SVG scroll inside their own box at phone width;
   - every link opens (use full real paths; `ls` a file before you link it).
   If you could not look at it, say so.

6. **Publish** with an icon and a one-sentence description. Link the page from the
   doc and the doc from the page footer.

7. **Reply in chat:** the link, 3-6 findings with numbers, the decisions that block
   the next step, and what was not verified.

## Keeping it alive

- **Doc and page change in the same turn.** Every decision goes into the markdown
  doc and the page together. The footer says "page and doc are updated together".
  The chat reply names both, with versions.
- **Republish to the same URL** with a short `label` per version ("Q4 decided",
  "S3 done"). On a conflict, merge your change into the live version. Never force.
- **Decisions stay visible.** A solved question shows "Decided <date>: <answer>"
  in place. Rejected options stay, with the reason. Nothing disappears silently.
- **Mark progress on the pages that exist.** Do not make a new page for status.
  Use a chip with a link to the change, a dated banner at the top, and
  "before / after <change>" wording on numbers. Mark "done differently", "partial"
  or "rolled back" honestly, and list what stays open.
- **Check before you mark done.** Look at recent merges and deploys. If the only
  proof is the user's word, say so on the page.
- **A later result reverses an earlier claim?** Add a dated callout "what changed
  since <date>". Do not rewrite history quietly.
- **Work splits into sub-tasks?** Give a sub-task its own page when it has its own
  steps and decisions. Keep a summary section on the parent page and link both ways.
- **A correction touches several pages?** Update all of them in the same pass.

## Rules

- Lead with the answer: counters, verdict or path first, detail below.
- Every table and chip group has a legend right under it.
- Status names describe the action ("extend existing", "write new",
  "decide, then write"), not size ("little code", "big").
- Add only what the user asked for. Offer other chat findings in one line; put them
  on the page only after a yes.
- When the user asks "what does this mean" about a page item, fix the page, not only
  the chat answer.
- Respect ownership: an option that needs another team's work is marked so, and
  dropped when the user says it is out of scope.
- Plans ship as one change set per repo. No day-by-day or canary phases unless the
  user asks for them.
- Before you write outward-facing text (a message to another person), explain the
  content to the user in chat first. Put the draft on the page with a Copy button.
- Pages are private by default. Tell the user to share from the page's Share menu.
