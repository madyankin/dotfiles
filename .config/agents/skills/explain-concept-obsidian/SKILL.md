---
name: explain-concept-obsidian
description: Build a rich HTML explainer of an academic or technical concept — math, algorithms, operating systems, networks, physics — with interactive charts, stepped diagrams, parameter sliders, and a five-question quiz, filed into the Obsidian vault with a markdown stub and Anki cards. Use when the user asks to learn, understand, or write a note about a concept, theorem, algorithm, or mechanism.
---

# Explain Concept → Obsidian

Turn one concept into a document that teaches it. Same deliverable as `explain-diff-obsidian`,
different subject matter: instead of a diff, the source is books, papers, existing vault notes,
and the web.

- `<Concept>.html` — self-contained page: prerequisites, intuition, formal treatment, worked
  example, misconceptions, and five clickable quiz questions.
- `<Concept>.md` — Obsidian stub: frontmatter, summary, takeaways, prerequisite wikilinks,
  and a record of the Anki cards pushed.

One concept per run. "Explain red-black tree deletion" is a run; "teach me algorithms" is a
request to pick a concept first.

## Output location

Topic folder under `3 Resources/`, chosen by subject:

| Subject | Folder |
|---|---|
| Algorithms, data structures, complexity | `3 Resources/Algorithms/` |
| OS, networks, systems, languages | `3 Resources/Software Development/` |
| Anything with no existing folder | create `3 Resources/<Subject>/` |
| Genuinely unclassifiable | `3 Resources/Explanations/` |

Filename is the concept, no date prefix — these are evergreen notes, unlike diff explainers.
Match the naming language of the folder's existing notes (`3 Resources/Algorithms/` is
Russian-titled).

Find the vault: `$OBSIDIAN_VAULT` if set, otherwise the `path` of the vault in
`~/Library/Application Support/obsidian/obsidian.json`:

```bash
VAULT="${OBSIDIAN_VAULT:-$(python3 -c 'import json,os;d=json.load(open(os.path.expanduser("~/Library/Application Support/obsidian/obsidian.json")));print(next(iter(d["vaults"].values()))["path"])')}"
```

The path contains spaces and lives in iCloud — quote it everywhere.

## Workflow

1. **Check the vault first.** `obsidian search query="…"` when Obsidian runs, otherwise
   `rg -il "<term>" "$VAULT"`. If a note on the concept already exists, say so and propose
   extending it instead of writing a near-duplicate. Never silently create the second copy.
2. **Gather sources, in this order of preference:** existing vault notes → books under
   `~/Documents/03 Resources/Books/` → the web. Record what you used in the stub's `sources`
   frontmatter. Prefer a source the user already owns over a blog post.
3. **Establish the prerequisite chain.** What must the reader already know? Which of those
   are covered by existing vault notes (link them), and which are gaps (say so explicitly in
   a callout rather than quietly assuming them).
4. **Build the narrative before the HTML:** where the concept comes from and what problem it
   solves → the smallest useful mental model → the formal statement → why it is true →
   what it costs → where people get it wrong.
5. **Write the `.html`** from `references/HTML_TEMPLATE.md`.
6. **Write the `.md` stub** from `references/STUB_TEMPLATE.md`.
7. **Validate** against the checklist below.
8. **Hand off**: both paths, a `file://` URL for the browser, one line on where the quiz is
   interactive, and an offer to push Anki cards.

## Page structure

Title, one-paragraph summary, table of contents, one continuous page.

1. **Prerequisites** — what the reader needs first, with an honest note on what this page
   assumes versus teaches. Short; it is a gate, not a chapter.
2. **Intuition** — the idea before the formalism. One concrete toy instance, carried through
   the whole page. If there is a picture in the reader's head that makes the concept obvious,
   this section's job is to install it.
3. **Formal treatment** — the precise definition or statement, then the argument: a proof
   sketch, an invariant, an amortized analysis, a derivation. Rigor at the level the concept
   demands, not decoration. The argument itself is stepped with `Viz.proof`, and a bound claim
   carries the chart that shows it.
4. **Worked example** — the toy instance from Intuition, stepped through with concrete
   numbers and the state visible at each step. This section is **always** an interactive
   stepper, never a static listing of steps.
5. **Common misconceptions** — the wrong models people carry, and what each one predicts
   incorrectly. Distractors in the quiz should come from here.
6. **Further reading** — the specific chapter, lecture, or paper, not a bare book title.
7. **Quiz** — exactly five interactive multiple-choice questions. See
   `references/QUIZ_RULES.md`; those rules are binding.

Prose: plain, precise, and willing to say "this is the part everyone finds confusing, and
here is why". Explain notation on first use — a symbol nobody parses teaches nothing.

## Math without a CDN

The page is self-contained, so MathJax and KaTeX are unavailable — they are CDN loads. Do not
write bare `$…$`; it renders as literal dollar signs in a browser.

- Inline: HTML with Unicode — `<span class="math">O(α(n))</span>`, `x<sub>i</sub>`,
  `Σ<sub>i=1</sub><sup>n</sup>`, `≤ ≥ ≠ ∈ ∉ ⊆ ∪ ∩ ∀ ∃ ⇒ ⇔ √ ∞ θ λ μ π σ ω`.
- Display: a `<div class="eq">` block using the template's styling, with `<sub>`, `<sup>`,
  and the `.frac` helper for fractions.
- Multi-step derivations: a two-column table, expression on the left, justification on the
  right. More readable than a wall of aligned equations anyway.

The stub is ordinary Markdown, so `$…$` and `$$…$$` **do** work there (the vault has
`obsidian-latex-suite`). Use real LaTeX in the stub, HTML math in the page.

## Figures are mandatory, and they go next to the text

For an academic note a figure is not decoration and not optional. **Every algorithm, data
structure, proof, derivation, complexity claim, physical process, protocol, and state machine
on the page gets its own interactive figure, placed immediately after the paragraph that
explains it.** `references/VISUALIZATIONS.md` carries the rule in full, the `Viz` CSS/JS
blocks, and every interaction pattern. Read it before writing the page.

| What the section explains | What it must carry |
|---|---|
| Algorithm | Stepper over the narrated example, one panel per operation |
| Data structure | `Viz.graph` of the structure, redrawn per operation in the stepper |
| Proof, derivation, complexity argument | `Viz.proof` stepper — one line at a time with its justification |
| Growth or bound claim | `Viz.chart` line plot of the competing bounds, crossover labelled |
| Physical process | Parameter slider over the governing equation, chart or diagram, play button |
| Protocol, state machine, lifecycle | `Viz.graph` stepped through the transitions |
| Threshold or regime | A slider the reader can push past the threshold |

Placement is part of the rule. A section that explains a mechanism carries its own figure;
four such sections mean four figures, not one gallery at the bottom. The paragraph says what
to look for, the figure lets the reader check it, the caption says what to notice. The
algorithm stepper steps through **the same example the walkthrough narrates**, never a
different one.

Skip a figure only when the subject genuinely has no state, no structure, and no varying
quantity — or when the honest data does not exist. **Never invent numbers to get a nicer
picture.** Plot the real function, cite real measurements, or say in one sentence, where the
figure would have gone, why there isn't one.

Beyond the mandatory set: scatter for data with spread (never a line through points that
aren't a function), bar charts for per-operation cost across a sequence, `.flow` for a linear
pipeline, `.ba` for exactly two states, tables for mappings and derivation justifications.
Reuse a small set of families. **Never ASCII art.** Label axes with units, give every `Viz`
call a real `aria` sentence, and carry one toy instance through Intuition, Formal treatment,
and Worked example rather than switching examples per section.

## Rendering reality (state this to the user on every run)

- **Browser = full fidelity.** Quiz clicks and interactive figures work only here. Hand over
  the `file://` URL and say so.
- **HTML Reader plugin (`obsidian-html-plugin`) = read-only preview, and it is not installed.**
  Its README says "almost all script codes cannot work": Text and High Restricted modes strip
  scripts, Balance (the default) sanitizes them, only Low Restricted / Unrestricted execute
  anything. Installing it is the user's call.
- **Local images never load** inside Obsidian. CSS and SVG figures, or inline data URIs.
- **Figures are script-driven**, so under HTML Reader they render empty. The collapsible data
  table `Viz.chart` emits is what survives there — keep it.
- **Mobile** sees the `.md` stub, which is why the stub carries the summary, the takeaways,
  and the key formulas rather than only a link. Obsidian renders Mermaid natively, so one small
  Mermaid diagram in the stub carries the structural idea without opening the page.

## HTML constraints

- One file. Inline `<style>` and `<script>`. No CDN, no external fonts, no remote images, no
  fetch. Works offline, forever.
- `<pre><code>…</code></pre>` for code and pseudocode. The `pre` CSS rule **must** include
  `white-space: pre` or `white-space: pre-wrap`, or the listing collapses to one line. Verify
  every block in the saved file.
- Escape derived text for HTML and JS contexts.
- JavaScript small, namespaced, dependency-free, attached with `addEventListener`.
- Responsive at phone width; visible focus states; correctness never conveyed by color alone.
- Support `prefers-color-scheme: dark` so it sits next to Obsidian's theme.

## Flashcards → Anki

After the files are written, offer to turn the quiz, the formal statement, and the takeaways
into Anki cards. Card creation is **not** this skill's job — invoke the `anki-cards` skill,
which owns the Anki MCP (`http://127.0.0.1:3141/`, tools prefixed `mcp__anki__`) and the
card-quality rules.

- Deck: `Explanations::<Subject>` — `Explanations::Algorithms`, `Explanations::OS`,
  `Explanations::Math`, `Explanations::Physics`. Create it if missing (`create_deck` supports
  `Parent::Child`).
- Tag every card with a concept slug plus the subject, so a later run can find them with
  `find_notes` and extend rather than duplicate.
- 5–12 cards. Definitions and statements are good cloze candidates; "why does X hold" and
  "what breaks if Y" are good Basic cards. Complexity bounds belong on their own card.
- Record what was pushed in the stub's card section as plain `front → back` bullets, and put
  the deck in the stub's `anki-deck` frontmatter.

> [!warning] Never write `:::` lines into the stub.
> The `flashcards-obsidian` plugin is installed and syncs any `:::` line it finds to Anki.
> With the MCP as the single source of cards, a `:::` line means every card exists twice.
> Use `→` in the record section.

## Language

Match the user's request language — asked in Russian, write the page and the stub in Russian,
and match the naming style of the target folder's existing notes. Notation, code, identifiers,
and established technical terms stay as they are conventionally written.

## Validation checklist

```bash
grep -nE 'https?://|src="\./|@import' "<file>.html"   # nothing outside prose links
grep -n 'white-space' "<file>.html"                   # every pre rule covered
grep -n '\$' "<file>.html"                            # no bare LaTeX — see Math without a CDN
grep -n 'aria-label' "<file>.html"                    # every figure described, none says just "chart"
grep -n ':::' "<file>.md"                             # must return nothing — see Flashcards
```

- five questions, correct-answer position varied, feedback hidden until click, answers absent
  from DOM order, `title` attributes, and accessibility labels
- stub frontmatter parses; the link to the `.html` resolves; every wikilink target exists
- **every algorithm, data structure, proof, bound, process, and state machine on the page has
  its own interactive figure, sitting next to the text that explains it** — walk the page
  section by section and check this before handing off
- every figure: the real function or cited data, axes with units, a caption saying what to
  notice, a data table left in place, sliders mirrored into an `<output>`, controls reachable
  by keyboard, no autoplay
- any skipped figure justified in one sentence where it would have gone
- prerequisite gaps stated explicitly, not assumed
- sources cited; say what you read and what you inferred; never assert a result you did not
  verify against a source

## Files

- `references/HTML_TEMPLATE.md` — page skeleton with CSS, math helpers, the stepper, and the
  quiz engine
- `references/VISUALIZATIONS.md` — when a figure is worth building, what kind to use, and the
  `Viz` chart/graph blocks with the slider and stepper patterns
- `references/STUB_TEMPLATE.md` — the markdown stub
- `references/QUIZ_RULES.md` — binding rules for writing the five questions
