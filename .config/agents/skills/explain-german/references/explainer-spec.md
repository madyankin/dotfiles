# Explainer Spec

The content contract. The same content goes into the HTML (`assets/template.html`) and into the note
(`obsidian-note.md`) — the HTML adds interactivity, the note stays readable on a phone.

## Metalanguage

- Explanations are in Russian. German appears only as material: examples, glosses, paradigms.
- Section headings are in Russian. German grammatical terms (Vorfeld, Satzklammer, Nebensatz, Dativ)
  stay as they are — the learner needs them to follow textbooks and teachers — but give a Russian
  expansion in brackets on first appearance.
- Address the reader as «ты», as in personal notes. No «мы рассмотрим», no «давайте».

## Level (inferred)

Estimate CEFR from the material, not from the user:

| Signal | Level |
|---|---|
| Präsens, simple main clauses, everyday vocabulary from the first thousand words | A1–A2 |
| Nebensätze, Perfekt/Präteritum, Passiv, modals, vocabulary 1–5k | B1–B2 |
| Konjunktiv I, nominal style, Funktionsverbgefüge, idioms, journalistic prose | C1 |

The level controls **only gloss density and the detail of morphological analysis**:

- A1–A2 — gloss every content word, analyse every form.
- B1–B2 — only low-frequency items and whatever the construction needs.
- C1 — only idioms, register and nuance; leave morphology alone unless it carries meaning.

The level does **not** reduce explanatory depth: an A1 text containing a Wechselpräposition still
gets a proper analysis, just phrased more simply.

State the level in one line and record it in `niveau` in the frontmatter. The user may override it.

## Sections (fixed order)

### 1. «Зачем» — what this buys the reader

2–3 sentences: what the reader will be able to do after this analysis. Concrete and checkable — not
"you will understand cases" but "you will stop confusing `in die Stadt` and `in der Stadt`". No
terminology.

### 2. «Интуиция» — intuition

The main section. The construction explained plainly, always **through contrast with Russian**:

- cases: Russian has six and they live in endings — German has four and they live in the article, so
  the article cannot be swallowed;
- aspect: Russian «читал / прочитал» — in German this is not a tense but context and a prefix;
- word order: nearly free in Russian — in German the verb is nailed to second position;
- Konjunktiv II ≈ «бы», but it lives in the verb form itself, not in a separate word.

The analogy comes **before** any table. A section with a table and no preceding intuition is
defective work. If there is no Russian analogy, say so: «в русском такого нет вообще, поэтому
опираться не на что, запоминаем как есть». That is more honest than a forced metaphor.

Close the section with one `leitbeispiel`: a short German example, its translation, what to watch
for, and the boundary where the hint stops applying. Use that same example in at least one analysis
step (`anker: true`) and return to it in the quiz. Expand any new term in Russian on first use.

### 2b. «Мнемоника» — mnemonics

`merksatz`: 1–3 lines, each ≤ 12 words. This is what the learner says to themselves **at the moment
of choosing a form**, not a summary of the section. Requirements:

- **Operational.** «Двигается → Akkusativ» works: it gives an action. «Wechselpräpositionen бывают с
  двумя падежами» does not: that is a fact, not a command.
- **Tested on the anchor example.** The mnemonic must fire on `leitbeispiel`. If it does not, it is
  about something else.
- **A dry formula beats a forced rhyme.** A jingle for its own sake is noise. Rhyme is acceptable
  only when it is itself shorter than the formula.
- Form is free: arrow rule (`Wohin? → Akk`), contrast (`рука — Akkusativ, глаз — Dativ`), acronym
  list, or a count («девять предлогов, два вопроса»).

### 3. «Что надо помнить» — what must be remembered

3–5 supporting facts without which the analysis will not move. Short, one line each. Put
`[[wikilinks]]` on existing notes around `[[Deutsch]]` where they exist. Do not retell the whole
textbook here — this is scaffolding, not a summary.

### 4. «Разбор» — the walkthrough

A literate walkthrough — the "literate diff" idea ported across.

- Chunks come in a **meaningful order**: the load-bearing structure first (who does what), then the
  trimmings (adverbials, subordinate clauses, modality). Not in the order the text presents them.
- Each chunk: German fragment → idiomatic translation → *why it is so*.
- `wort` (literal) — **only when German word order or government diverges from Russian** and the
  difference explains the construction. If the literal translation matches the idiomatic one, omit it.
- `warum` — up to 45 words. If it does not fit, the chunk is too big: cut the chunk, not the
  explanation.
- Overlapping chunks are fine: one sentence may be shown twice, from different angles.
- Keep the main explanation open. Put technical qualifications and exceptions in
  `details: [{titel, text}]`, and reference tables in `reference`. That way depth collapses rather
  than disappears.

In `grammatik` mode a "chunk" is not a fragment of text but a step of the rule: minimal example →
the same example with one parameter changed → what broke and why.

### 5. Visualisations inside the walkthrough

The figures and their `DATA` live in `interactive.md`; this section is only the placement contract.

1–4 figures (at least two in `text` and `grammatik` — the builder checks). Each has a unique `id`, a
self-contained `aria`, a `hinweis` (≤14 words, "what to manipulate") and a `beobachtung` (≤20 words,
"what you should have noticed"; hidden in the HTML until interaction). An analysis step references
it via `figure_id` and the renderer places the figure immediately after that step — there is no
separate gallery.

A figure must **replace** a paragraph, not accompany it: once you place a diagram, cut the prose
beside it to one line. Do not draw a chart that duplicates the text.

### 6. «Грабли» — the rakes

Mistakes typical of a Russian speaker specifically, and only those applicable to this material:

- false friends (`Termin` ≠ термин, `Familie` ≠ фамилия, `bekommen` ≠ become);
- an article where Russian has none, and its absence where you expect one;
- word order: verb not in second position, forgotten Verbletztstellung in a Nebensatz;
- verb and preposition government (`warten auf` + Akk, `denken an` + Akk, `helfen` + Dat);
- calques from Russian in prepositions (`на неделе`, `в выходные`).

In `fehler` mode this section is built directly from the user's own mistakes: **было → стало →
почему**, and the quiz targets exactly those spots.

### 7. «Квиз» — the quiz

Exactly 5 questions. See below.

### 8. «Карточки» — the cards

5–12 of them, following the `anki-cards` skill's rules: one fact per card, a question on the front,
the shortest correct answer on the back. The deck comes from **`explainer_anki_deck`**; tags are
`deutsch`, `explainer`, topic, level, mode. For German specifically:

- a noun always carries its article and plural: `die Entscheidung, -en`;
- a verb with government gets a card about the government, not the translation:
  `warten ??? (ждать кого-то)` → `auf + Akk`;
- an irregular verb gets all three forms on one card;
- do not make a "translate this word" card for a word that appeared once and is not in the frequency
  core.

## Quiz rules

The quiz is the speed regulator. The point: until it is passed, the topic does not count as
understood.

- **Exactly 5 questions**, of mixed types: 2 × multiple choice, 2 × type the form, 1 × assemble the
  word order.
- They test **understanding, not recall of the text**: "why is it Dativ here" — yes; "which word was
  third in the first sentence" — no.
- Every distractor must be a plausible mistake, not filler.
- Each question has a `fokus`: one specific skill under test. At least one question carries a
  `figure_id` and requires reading or manipulating the associated diagram.
- Before answering, correctness must not be betrayed by phrasing length, a special class, ordering,
  `aria-label` or any other form. The positions of correct options must vary.
- Immediate one-line feedback: why the correct answer is correct **and** why the chosen wrong one is
  wrong.
- Free input is normalised: trim, case-insensitive, `ä≡ae`, `ö≡oe`, `ü≡ue`, `ß≡ss`, plus an explicit
  list of acceptable alternatives in `DATA`.
- Closing gate line: «Не считай тему пройденной и не заливай карточки, пока не соберёшь 5/5.»

## Length and budget

Length is set by **a counter, not a feeling**. The builder counts explanatory words (Russian prose;
markup and German examples do not count) and refuses to build an overrun, naming the field and the
number.

| Field | Ceiling, words |
|---|---|
| `zweck[i]` | 35 |
| `intuition` (a `p` paragraph) | 45 |
| `merksatz[i]` | 12 |
| `leitbeispiel.ziel` / `.grenze` | 20 |
| `stuetzen[i]` | 18 |
| `analyse[].warum` | 45 |
| `analyse[].details[].text` | 60 |
| `fallen[].warum` / `.text` | 30 |
| figure `hinweis` | 14 |
| figure `beobachtung` | 20 |
| **total per learning block** | **450** |

A block is an `analyse` step with a `titel`. No `titel` anywhere means one block and a budget of 450.
Two blocks, 900. Splitting the material into explicit blocks is the only way to buy length — not
stretching paragraphs.

**Cutting order on overrun** (top of the list is cut first):

1. `details` — collapsible qualifications. A qualification that did not fit is not needed.
2. `wort` — the literal translation wherever it matches the idiomatic one.
3. `stuetzen` — scaffolding that duplicates the mnemonic.
4. `intuition` paragraphs — keep one contrast with Russian, the strongest.
5. `analyse` steps — merge adjacent ones or move repetitive ones into `solutions`.

**What is never cut:** the diagrams, `merksatz`, the `warum` of the anchor step, and the five quiz
questions. If staying within budget means dropping a diagram, the material is two blocks, not one.

Input guideline: `text` — up to ~600 words of source, `vokabeln` — up to ~20 words, `grammatik` —
one construction, not "all the tenses". More than that: propose a split and explain the boundaries.

**A long exercise compresses to its core.** Fifteen near-identical tasks are one rule, one example
where it is visible, and a key in `solutions`. Do not turn a list of exercises into a list of
analysis steps.

## What not to do

- Do not translate the whole text as a separate block — it destroys the point of the analysis.
- Do not dump full paradigms when the material uses two cells out of sixteen.
- Do not write «как известно», «очевидно», «просто запомни» without a reason.
- Do not mix levels: having decided on B1, do not gloss `und` and `aber`.

## Provenance and appendices

In `analyse`, record `herkunft` (`zitat` / `loesung` / `beispiel`) and `quelle` — the printed page or
the exercise. Do not call reconstructed text a quotation; a new example changes exactly the parameter
under study. Reference tables go in `reference`, exercise keys in `solutions` — not in «Грабли». The
five questions test the core skills, not the whole reference section. The remaining mechanics are in
`interactive.md` ("Additional DATA fields") and `production.md`.
