# Quiz rules

Five questions. Not four, not seven. They are the comprehension test that gates shipping the
change, so treat their design as part of the explanation.

Before emitting the page, inspect all five **as a set**, not one at a time.

## Difficulty

- Medium: hard enough that you must have understood the substance of the change to answer,
  never a gotcha, never trivia.
- Ask about **behavior, causality, contracts, edge cases, and trade-offs**. "What happens if
  the cache entry expires mid-request?" beats "which file was modified?".
- Every answer must be derivable from the page. If it requires knowledge the page never
  gave, either teach it above or drop the question.
- Never a question whose answer is a phrase the reader can pattern-match from a nearby
  paragraph.

## Options

- Four options per question.
- **Shuffle option order independently per question.** A deterministic shuffle with a
  per-page seed is fine; the visible order must differ across the five.
- **Balance correct-answer positions** across the five as evenly as possible. Never leave the
  correct answer always first, always last, or in any recognizable pattern.
- Options comparable in length, grammar, specificity, and confidence. The classic tell is a
  correct answer that is longer, more hedged, and more technically precise than its
  distractors — shorten it or enrich them.
- Every distractor encodes a **real misunderstanding** of this change: the behavior someone
  would predict from the old code, an off-by-one in the new invariant, a plausible but wrong
  ordering. No joke answers, no impossible claims.
- No "all of the above", no "none of the above".

## Feedback

- Reveal feedback only after the reader selects.
- Mark the selected option, state whether it is correct, and explain **why** — the relevant
  behavior or code path, and where useful the misconception the distractor encodes.
- Correct answers and explanations live in the page's JS data or DOM so everything works
  offline.

## Leak prevention

The reader must not be able to spot the answer before clicking. Check all of these:

| Leak | Check |
|---|---|
| Styling | No class, color, or attribute distinguishes the correct option pre-selection |
| DOM order | Correct answer is not systematically first in source order |
| `title` / `aria-label` | Describe the option, never its correctness |
| Text shape | Punctuation, hedging words, and length do not correlate with correctness |
| Explanations | Not present in the DOM as visible text before selection |

## Self-check before writing the file

1. Write the five questions out with their correct answers.
2. List the correct positions — are they spread across 1–4?
3. Read the four options of each question aloud. Could you pick the right one without
   reading the page? If yes, rewrite the distractors.
4. Does each question test a different aspect? Five questions about the same function is one
   question asked five times.
