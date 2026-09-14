# Building and verifying explainers

## PDFs and selected pages

Use the available Python with pypdf; for rendering, pypdfium2/Pillow or the PDF skill's tools.

```sh
python scripts/inspect_pdf.py INPUT.pdf --out work/ingest
python scripts/inspect_pdf.py INPUT.pdf --out work/ingest --render 4 5 9 --rotate 90
```

`--render` numbers start at 1 and refer to the PDF, not the textbook. Empty text is a reason to
look at the scan, not to call the page blank. Even non-empty text should be checked for truncated
columns. Look at the images and fill `printed_pages` in page-map.json by hand — one PDF spread can
hold two printed pages. Never equate PDF labels with printed numbers without checking. Transcribe
what is legible verbatim; do not guess handwriting. When the user has grouped the material, show a
short map of the file composition. Do not renegotiate a grouping that is already explicit.

## Content and build

One DATA JSON per HTML. The main route runs from the load-bearing structure outwards to the details.
Add `leitbeispiel` and carry it into `analyse` with `anker: true`. Give every figure an `id` and an
`aria`, and reference it from the matching analysis step via `figure_id`. Each figure is mounted
exactly once. For large material use several blocks (`analyse[].titel`); each block gets its own
450-word budget. Compress long, repetitive exercises to the rule plus one example, with the keys in
`solutions`. Keep collapsible glossaries and tables in `reference`, exercise keys in `solutions`.
Record provenance and page in `analyse`: a quotation, a reconstructed answer, or a new example. Add
`requested_pages`, `pages` and `page_map` to meta when the user selected pages.

```sh
python scripts/build.py work/part-1.json work/part-2.json --out outputs
```

The builder checks the basic schema, the five questions, the answer options, the token set, name
uniqueness, agreement between declared and covered pages, the presence of mnemonics, the per-mode
figure minimum, and **the word budget**. A refusal like `analyse[3].warum: 71 words, limit 45` is
not a builder bug: shorten the named field following the order in `explainer-spec.md` — do not work
around the check by splitting into fictitious blocks. Actual usage is written to `meta.woerter`.
Pages may be omitted when there is no explicit grouping.

It produces HTML from the current template, plus a ZIP when there are several files. The script does
not write to Obsidian and does not push to Anki. If Obsidian was chosen, build the full Markdown
version per `obsidian-note.md` — including the prose explanation of the diagrams and the appendices
— and write it through the CLI. Do not substitute an inline download link for the note the user
asked for, and do not claim a note exists before it has been written. Preserve relative links
between HTML files if you add them; the ZIP must contain their targets.

## Visualisation as part of the explanation

Show what changing one parameter does: what moves on the diagram and what stays put. Choose at least
one fitting explanatory diagram per HTML, unless the material genuinely has no meaningful spatial,
temporal or semantic relation. A quiz and a collapsible glossary do not substitute for such a
diagram.

- Tenses: `zeitstrahl`, showing the past reference point and the preceding event.
- Dativ/Akkusativ: `valenz`, the verb and its participant roles with arrows.
- Object order: `feldermodell`, the same fields for the original sentence and for the pronoun
  substitution.
- Word composition: `wortbau`; semantic relations between words: `wortnetz`.

Every example is precomputed. SVG/CSS and the controls work without a network and carry text
labels. If a diagram reveals a new distinction, explain it before the quiz asks about it.

## Three independent checks

1. **Content:** verify printed pages and exercise coverage; check cases, forms, translations,
   register, and that new examples are distinguishable from quotations. The five questions test the
   core skills, not the whole reference section.
2. **Function:** after building, run the unified verifier:
   `python scripts/verify.py outputs/a.html outputs/b.html`. It exercises the schema, the renderer,
   all five correct answers, the figure controls, the embedding of diagrams into the analysis, the
   links between quiz and diagrams, the absence of external dependencies, and obvious placeholders.
   It does not check real browser layout.
3. **Appearance:** if a browser tool is permitted, check narrow and wide screens, SVG labels,
   horizontal scrolling of tables, appendix expansion and the controls. Do not circumvent a ban on
   the browser tool via another URL or server. If no preview is available, say honestly that the
   visual check was not performed; never call a DOM test an appearance check.

Deliver links to each HTML and the combined ZIP immediately. State the actual status of the notes
and the checks.
