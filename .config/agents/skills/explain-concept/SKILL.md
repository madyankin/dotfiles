---
name: explain-concept
description: Build a rich HTML explainer of an academic or technical concept — math, algorithms, operating systems, networks, physics — with interactive charts, stepped diagrams, parameter sliders, and a five-question quiz, filed into the Obsidian vault with a markdown stub and Anki cards. Use when the user asks to learn, understand, or write a note about a concept, theorem, algorithm, or mechanism.
---

# Explain Concept → Obsidian

Turn one concept into a document that teaches it. Same deliverable as `explain-diff`,
different subject matter: instead of a diff, the source is books, papers, existing vault notes,
and the web.

- `<Concept>.html` — self-contained page: prerequisites, intuition, formal treatment, worked
  example, misconceptions, and five clickable quiz questions.
- `<Concept>.md` — Obsidian stub: frontmatter, summary, takeaways, prerequisite wikilinks,
  and a record of the Anki cards pushed.

One concept per run. "Explain red-black tree deletion" is a run; "teach me algorithms" is a
request to pick a concept first.

## Output location

Subject folder from the `explainer_subjects` map in the `Explainers` config note; anything
unmatched goes in `explainer_folder`. Both are resolved per
`obsidian-cli/references/vault-resolution.md` — no folder name is hardcoded here.

If `explainer_subjects` names a subject that has no folder yet, create it. If the map is
absent entirely, put everything in `explainer_folder`.

Filename is the concept, no date prefix — these are evergreen notes, unlike diff explainers.
Match the naming language of the destination folder's existing notes: a lone English page in
a Russian-titled folder is a wart.

**If a note with that exact name already exists**, you are not allowed to overwrite it and not
allowed to write a near-duplicate beside it. Pick one, in this order:

1. The existing note already is the explainer → extend it, no new files.
2. The existing note is a hub or a set of flashcard fragments and the explainer genuinely adds
   a layer (a proof, an analysis, an interactive walkthrough) → new file with a **suffix that
   names the added layer**, not a vague qualifier: `«Concept» — полный разбор`,
   `«Concept» — амортизированный анализ`, `«Concept» — доказательство`. Then **link the new
   page from the existing note**, so the vault has one entry point rather than two rivals.
3. The concept is narrower than the existing note → name the file for the narrow thing
   (`Сжатие пути в Union-find`), not for its parent.

Say which of the three you picked and why, before writing anything.

Resolve the vault and the config note per `obsidian-cli/references/vault-resolution.md`.

**No vault, no config note, or Obsidian not running → write the HTML only**, where the user
asked or to the current directory, and say where it landed. Never invent a path.

Vault paths contain spaces and may live in iCloud — quote them everywhere.

## Workflow

1. **Check the vault first.** `obsidian search query="…"` when Obsidian runs, otherwise
   `rg -il "<term>" "$VAULT"`. If a note on the concept already exists, say so and propose
   extending it instead of writing a near-duplicate. Never silently create the second copy.
2. **Gather sources, in this order of preference:** existing vault notes → books under
   `explainer_sources`, when that key is set → the web. Record what you used in the stub's
   `sources` frontmatter. Prefer a source the user already owns over a blog post.

   **Verify chapter and page numbers against the file, never from memory.** `pdftotext` is
   installed; dump once and grep the table of contents and the statement itself:

   ```bash
   pdftotext "«book».pdf" - | grep -n -i -A12 "«chapter title»"       # confirm ch./section
   pdftotext -f «first» -l «last» "«book».pdf" - | grep -n "Proposition\|Theorem\|Lemma"
   ```

   A citation you did not open is a guess. If you could not verify one, say so in the handoff
   rather than printing it as if you had.
3. **Reconcile with what the vault already claims.** If an existing note contradicts the
   source — a wrong bound, a buggy snippet, a stale API — say so explicitly and offer to fix
   that note. Finding the contradiction is the most valuable thing this skill does on a
   subject the user has already studied; quietly writing a correct new page next to a wrong
   old one wastes it.
4. **Establish the prerequisite chain.** What must the reader already know? Which of those
   are covered by existing vault notes (link them), and which are gaps (say so explicitly in
   a callout rather than quietly assuming them).
5. **Build the narrative before the HTML:** where the concept comes from and what problem it
   solves → the smallest useful mental model → the formal statement → why it is true →
   what it costs → where people get it wrong.
6. **Write the `.html`** from `references/HTML_TEMPLATE.md`.
7. **Write the `.md` stub** from `references/STUB_TEMPLATE.md`.
8. **Run `node references/verify.js "<file>.html"`** and fix until it prints PASS, then walk
   the rest of the checklist below.
9. **Hand off**: both paths, a `file://` URL for the browser, one line on where the quiz is
   interactive, what you verified against a source versus inferred, and an offer to push Anki
   cards.

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
   numbers and the state visible at each step. **If the concept is an algorithm, this section
   is a step-by-step visualization, and that is not negotiable** — see "An algorithm is
   stepped, always" below.
5. **Common misconceptions** — the wrong models people carry, and what each one predicts
   incorrectly. Distractors in the quiz should come from here.
6. **Further reading** — the specific chapter, lecture, or paper, not a bare book title.
   **Anything with a stable web address is a hyperlink**, never a bare identifier the reader
   has to retype — see "Sources are clickable" below.
7. **Quiz** — exactly five interactive multiple-choice questions. See
   `references/QUIZ_RULES.md`; those rules are binding.

## Write for someone who has not met this before

**The reader** is a competent programmer who has never seen this concept. They can read code
and follow an argument. They do not know your notation, your jargon, why the naive approach
fails, or which of the five things on screen is the important one. Every sentence on the page
must be reachable from that starting point.

**Accessible does not mean less.** The usual way to make a hard thing readable is to delete
the hard parts. That is forbidden here. You may not drop a detail, a bound, a caveat, a
failure mode, or a step of the proof. What you may change is the **order** things arrive in
and the **scaffolding** around them. Simplification happens in sequence and framing, never in
content. If a page got easier to read and shorter on substance, it got worse.

**Depth is collapsed, not cut.** `<details>` is the mechanism that makes this possible: the
main line stays walkable, the full derivation, the edge cases, and the assembled listing sit
one click away. Nothing is removed to protect the reader — it is folded so they choose when to
open it. Use it for the third-level detail, never for something the argument depends on.

### The three moves that do most of the work

**Name before notation.** Every symbol gets a word before it gets a glyph, in the same
sentence. Not "let <span class="math">α(n)</span> be the inverse Ackermann function" — the
reader who needed that sentence learned nothing. Instead: what it counts, how fast it grows,
what value it takes for real inputs, and *then* the symbol. Same for subscripts, same for
operators the reader may not have seen, same for the word "amortized".

**Concrete before general.** A number before a variable, one instance before the class, the
specific failure before the general rule. The page already carries one toy instance through
every section — lean on it. "Merging a tree of 3 into a tree of 5" lands; "merging
<span class="math">S<sub>i</sub></span> into <span class="math">S<sub>j</sub></span> where
<span class="math">|S<sub>i</sub>| ≤ |S<sub>j</sub>|</span>" is the same fact after the reader
already believes it.

**Staged truth, with the debt paid.** Say the useful simple version first, **mark it as
simplified in the same breath**, and come back to it later on the page. "Think of the rank as
the tree's height — exactly true until we add path compression, which §6 fixes." An
unmarked simplification is not pedagogy, it is a confident wrong explanation; an unpaid one
sends the reader away believing it. Track your debts and settle every one.

### Sentence-level rules

- **First use of a term defines it, in the same sentence.** No "as is well known", no term
  whose definition arrives two sections later. If a sentence needs a word the page has not
  introduced, either introduce it there or move the sentence.
- **Never wave a step away.** *Очевидно, тривиально, разумеется, как известно, obviously,
  trivially, clearly, of course* — each tells a stuck reader that the problem is them. If a
  step really is immediate, showing it costs one line; if it is not, the word was a lie.
  `verify.js` fails on these outright.
- **Watch the dismissive *просто* / *simply* / *just*,** but only in that sense. Russian
  «просто» is usually the adverb "merely" — *«просто невообразимо медленно»* is fine and
  precise. What is banned is the construction that shrugs at the reader: *«это просто»*,
  *«просто возьмите»*, *"simply add"*, *"just call"*. `verify.js` flags that pattern and
  leaves the adverb alone.
- **Name the confusion out loud.** "This is the part everyone gets wrong, and here is why" is
  worth more than another paragraph of careful phrasing. The misconceptions section is not the
  only place this belongs.
- **An analogy must state where it breaks.** A metaphor the reader keeps past its limit costs
  more than it gave. One sentence: "this picture stops working once X, because Y."
- **Prefer the short Germanic word and the active voice**, but never at the cost of precision.
  "The union is irreversible" beats "deletion functionality is not supported", and both beat
  an ambiguous sentence.

### Literate listings

Knuth's rule, applied to a teaching page: **code is exposition, and its order follows the
reader's thinking, not the compiler's.** A thirty-line listing dropped into the page is a wall
the reader either already understood or will skip. Break it.

Each chunk is introduced by prose that says **why it exists** before the reader sees **what it
does**, and followed by one line on what it costs or what invariant it just established:

```html
<div class="lit">
  <p class="lit-why">«The problem this piece solves, in one sentence — before any code.»</p>
<pre><code>«the chunk — small enough to hold in your head, one idea»</code></pre>
  <p class="lit-then">«What it just established, or what it costs.»</p>
</div>
```

Then, once the pieces are understood, give the whole thing so it can be copied and run:

```html
<details>
  <summary>«Собрать целиком»</summary>
<pre><code>«the complete, runnable listing»</code></pre>
</details>
```

Rules for chunks:

- One idea per chunk. If the `lit-why` sentence needs an "and", split the chunk.
- The chunks concatenate into the full listing — no drift between the pieces and the whole.
- Comment the **why** in the code, since the **what** is the line itself and the **how** is the
  prose above it.
- A line the reader will get wrong gets its own chunk, even if it is one line. The
  `parent[find(p)] = b` kind of line has earned the space.
- `verify.js` fails on a `<pre>` over 25 lines outside a `<details>` — that is the mechanical
  floor, not the goal.

**The code on the page is exposition, not production.** It is read once, slowly, by someone
meeting the idea for the first time, and it is never profiled. Optimise it for that reader:

- **Name the intermediate instead of nesting the call.** `Math.min(1, Math.max(0, rate *
  (target / Math.max(prev.sp, 1e-9)) * (prev.r / r)))` is one expression doing four things.
  Give the clamp a name, give each correction factor a name, and let the last line read like
  the sentence above it:

  ```js
  var moneyMiss = target / Math.max(prev.sp, EPS);   // недобрали или перебрали в прошлом часе
  var trafficShift = prev.r / r;                     // трафика стало больше или меньше
  var winShift = prev.w / win(b);                    // выигрывать стало легче или труднее
  rate = clamp(rate * moneyMiss * trafficShift * winShift, 0, 1);
  ```

- **Two levels of nesting is the ceiling** in any one expression. A third means a name is
  missing.
- **Every magic number gets a name.** `1e-9` is `EPS`; `0.7` is `LOAD_FACTOR`. The reader
  cannot look them up.
- **One idea per line.** A line that needs horizontal scrolling has already failed, and the
  page is 46rem wide — roughly 90 monospace columns at this size. Wrap before that.
- **Guard and return early** rather than nesting `if`s; the happy path should read straight
  down the left margin.
- If the real implementation genuinely is dense, **show the unpacked version and say so** in
  one sentence: "здесь то же самое, разложенное на шаги". Never paste production density into
  a teaching page and hope the reader untangles it.

### What this does not license

Not condescension: the reader is inexperienced in this subject, not slow. Not padding — a
longer page is not a friendlier one, and every sentence still has to earn its line. Not
hedging: "roughly", "sort of", and "more or less" are how precision gets lost while sounding
approachable. Not dropping the proof, the bound, or the failure case, ever.

## An algorithm is stepped, always

If the concept is an algorithm — or a data structure, which is an algorithm plus a shape — the
page **must** carry a stepper that runs it. Not a numbered list of steps. Not a single
before/after pair. Not "the trace is in the code comments". A control the reader drives, one
panel per operation, with the whole state drawn at every step.

The contract:

- **One panel per operation**, and the panel shows the **full state**, not a delta — a reader
  who lands on step 7 must understand step 7 without replaying 1–6.
- **The steps are produced by running the real algorithm in the page's JS**, never
  hand-written. Hand-written states drift from the code printed two paragraphs above, and the
  reader will find the discrepancy before you do. Running it also means the counters in the
  captions are measurements, not recollections.
- **It steps the same input the prose narrates.** Not a second example, not a simplified one.
- **The structure is drawn as a structure** — `Viz.tree` for anything with parent pointers,
  `Viz.graph` for general topology — alongside the raw array or table the code indexes. Seeing
  both, and seeing them agree, is most of what the figure teaches.
- **Back, forward, and ▶** on every stepper. Play is opt-in, never autoplaying.
- **A step shows something, or it is not a step.** Moving a highlight bar down a list is not
  stepping — the reader who was stuck on line 6 is still stuck on line 6, now with buttons.
  Every step either draws its own figure or marks the change inside the expression; proof and
  derivation steppers use `Viz.proof`'s `show` and its `mk-sub` / `mk-gone` / `mk-new`
  markers. `VISUALIZATIONS.md` has the table of step kinds and what each one draws;
  `verify.js` fails a stepper whose steps render neither.
- **Counters that carry the argument**: depth, comparisons, pointer hops, components, whatever
  the complexity claim is about. The number the reader watches move should be the number the
  analysis section bounds.
- **A variant selector when the page compares algorithms.** Union-find has four
  implementations; a sorting note has the naive and the improved partition. Re-running the
  *same input* under each variant, with the counters side by side, is what makes an
  improvement land. `mountStepper` returns `{render, reset, goto, at}` precisely so the
  selector can swap the steps and redraw.

An algorithms page therefore has, at minimum: the stepper, a `Viz.proof` walk for the bound,
and a chart of the cost. If you wrote an algorithms explainer with one figure, you have not
finished it.

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
| Algorithm | Stepper over the narrated example, one panel per operation, steps generated by running the real code |
| Data structure | `Viz.tree` (parent pointers) or `Viz.graph`, redrawn per operation inside the stepper |
| Proof, derivation, complexity argument | `Viz.proof` stepper — one line at a time with its justification |
| Growth or bound claim | `Viz.chart` line plot of the competing bounds; `yScale: "log"` when they differ by orders of magnitude |
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

When you need data the sources do not publish — "how much does this actually cost at
n = 4000?" — the answer is not to estimate it and not to drop the figure. **Have the page
compute it**: implement the thing in the page's JS and measure it live, seeded so the numbers
are reproducible. Say in the caption that it is a measurement on one input, not a worst-case
bound. The same implementation then drives the stepper, so the walkthrough and the chart can
never disagree.

Budget: one figure per mechanism, and reuse a family rather than inventing a new one per
section. If two sections would carry the same figure, they are one section or one of them
needs a different state of it. Eight figures on a deep algorithm is right; eight on a
definition means most of them are decoration.

Beyond the mandatory set: scatter for data with spread (never a line through points that
aren't a function), bar charts for per-operation cost across a sequence, `.flow` for a linear
pipeline, `.ba` for exactly two states, tables for mappings and derivation justifications.
Reuse a small set of families. **Never ASCII art.** Label axes with units, give every `Viz`
call a real `aria` sentence, and carry one toy instance through Intuition, Formal treatment,
and Worked example rather than switching examples per section.

## Sources are clickable

A citation the reader has to copy into a search box is a citation they will not follow.
Anything with a stable address becomes an `<a href>` at the moment you write it:

| Written as text | Becomes |
|---|---|
| `arXiv:1610.03013` | `<a href="https://arxiv.org/abs/1610.03013">` |
| a DOI | `<a href="https://doi.org/«doi»">` |
| `RFC 9110` | `<a href="https://www.rfc-editor.org/rfc/rfc9110">` |
| a paper with no DOI but a canonical page | that page |
| a lecture, course, or spec | its page |

Rules:

- **Link text is the title**, or the identifier — never a naked URL, and never "here".
- **A book the user owns is not a link.** It is a file on their disk; cite chapter, section,
  and page instead, and name the `explainer_sources` location it came from.
- **Do not invent a URL.** An arXiv ID or DOI maps to its address mechanically and that is
  safe; anything else you have not actually seen stays unlinked, and you say so.
- The page's no-external-resources rule is about **loading** — scripts, styles, fonts, images,
  `fetch`. Prose links load nothing until the reader clicks. They are not merely allowed, they
  are required. `verify.js` distinguishes the two and fails on a bare `arXiv:` / `doi:` /
  `RFC N` left unlinked.

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
which owns the Anki connection and the card-quality rules.

- Deck: `<explainer_anki_deck>::<Subject>`, from the `Explainers` config note — subject taken
  from the same classification used for the output folder. Create it if missing (`create_deck`
  supports `Parent::Child`). No `explainer_anki_deck` → build the cards, offer them, and skip
  the push.
- Tag every card with a concept slug plus the subject, so a later run can find them with
  `find_notes` and extend rather than duplicate.
- 5–12 cards. Definitions and statements are good cloze candidates; "why does X hold" and
  "what breaks if Y" are good Basic cards. Complexity bounds belong on their own card.
- Record what was pushed in the stub's card section as plain `front → back` bullets, and put
  the deck in the stub's `anki-deck` frontmatter.

> [!warning] Never write `:::` lines into the stub.
> If the `flashcards-obsidian` plugin is in use, it syncs any `:::` line it finds to Anki.
> With the MCP as the single source of cards, a `:::` line means every card exists twice.
> Use `→` in the record section.

## Словарь: terms in Russian output

Russian pages and stubs use Russian words. A transliterated English term is not a technical
term, it is an untranslated one, and it reads as sloppy in a note the user will keep for years.

| Never write | Write instead |
|---|---|
| волт, вольт | **хранилище**, **заметки**, or **Obsidian** — pick by what the sentence is about: the storage, its contents, or the app |

The rule behind the table, for terms it does not list yet: **if a normal Russian word exists,
use it.** Transliterate only when there is genuinely nothing — and a word that merely feels
shorter in English does not count.

What stays as conventionally written, and must not be translated: notation, identifiers, code,
file names, product names (Obsidian, Anki, Swift), and established technical terms that the
field itself writes in English or in transliteration (`union-find`, `find`, `хеш-таблица`,
`кеш`). Translating those is the opposite mistake and just as bad.

`verify.js` fails on the entries in the table. When the user corrects a word, add a row —
that is the whole maintenance story for this section.

## Language

Match the user's request language — asked in Russian, write the page and the stub in Russian,
and match the naming style of the target folder's existing notes. **When the invocation
carries no natural language at all** (`/explain-concept union-find` is a bare term,
not a sentence), fall back to the language of the target folder's existing notes. A lone
English page in a Russian-titled folder is a wart; do not create it on a technicality. Notation, code, identifiers,
and established technical terms stay as they are conventionally written.

## Validation checklist

Run the harness first. It parses the page, executes every script, clicks every button, drags
every slider, cycles every select, ticks every interval, and fails on a thrown error, an empty
figure mount, a stepper that does not open at `1 / n`, quiz feedback visible before a click, a
quiz that is not five questions, an external URL, a missing `white-space: pre`, a bare `$`, a
leftover `«placeholder»`, or an `aria` sentence too short to be a sentence.

```bash
node references/verify.js "<file>.html"   # must print PASS
grep -n ':::' "<file>.md"                 # must return nothing — see Flashcards
```

`http://www.w3.org/2000/svg` is an XML namespace, not a network load; the harness knows and
ignores it. Nothing else with a scheme belongs in the file.

What the harness cannot judge, and you still must:

- distractors encode real misconceptions and no option is guessable from its shape alone
- stub frontmatter parses; the link to the `.html` resolves; every wikilink target exists
- the stub carries its Mermaid diagram and does not claim Anki cards that were never pushed
- **every algorithm, data structure, proof, bound, process, and state machine on the page has
  its own interactive figure, sitting next to the text that explains it** — walk the page
  section by section and check this before handing off
- **the algorithm is stepped**: a real stepper, steps generated by running the code, full
  state per panel, counters that match the bound being claimed, and a variant selector if the
  page compares implementations
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
  `Viz` chart/graph/tree blocks with the slider and stepper patterns
- `references/verify.js` — `node references/verify.js page.html`: runs the page in a stub DOM,
  exercises every control, and fails on anything a grep cannot see
- `references/STUB_TEMPLATE.md` — the markdown stub
- `references/QUIZ_RULES.md` — binding rules for writing the five questions

## Changelog

- 2026-09-13 — retro after the Union-find run. Shipped `references/verify.js` (runs the page
  in a stub DOM, exercises every control) and `Viz.tree` (parent-pointer forest layout, was
  hand-rolled per run); `Viz.chart` gained `yScale: "log"` and rounded axis labels; the quiz
  engine now balances correct-answer positions by construction, so the manual position check
  and the SEED hunt are gone from `QUIZ_RULES.md`; added the filename-collision rule, the
  "an algorithm is stepped, always" contract, `pdftotext` source verification, the
  reconcile-with-existing-notes step, the bare-term language fallback, and a figure budget.
  Replaced the grep checklist with the harness.
- 2026-09-13 — added "Write for someone who has not met this before": accessibility is bought
  with sequence and scaffolding, never by dropping detail; depth folds into `<details>` instead
  of being cut. Name before notation, concrete before general, staged truth with the debt paid.
  Literate listings (`.lit` chunks, assembled version folded) replace code walls. `verify.js`
  now lints prose for words that wave a step away and for listings over 25 lines outside
  `<details>`. The blanket ban on «просто» was wrong — it is normally the adverb "merely"; only
  the shrug («это просто», "simply add") is flagged.
- 2026-09-13 — a stepper must show the step, not highlight it: `Viz.proof` gained `show(fig, i)`
  and the `mk-sub` / `mk-gone` / `mk-new` rewrite markers, plus a table of step kinds and what
  each draws. Shipped `Hl`, a dependency-free syntax highlighter for every listing. Added the
  «Словарь» section (волт → хранилище/заметки/Obsidian), the rule that page code is exposition
  and gets named intermediates instead of nested calls, and the rule that any source with a
  stable address is a hyperlink. `verify.js` now separates network *loading* (banned) from
  prose links (required), and fails on unhighlighted listings, bare `arXiv:`/`doi:`/`RFC N`,
  banned words, and proof steppers that only move a highlight.
