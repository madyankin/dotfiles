# Quiz rules

Five questions. Not four, not seven. They are the comprehension test that tells you whether
you actually understood the concept, so treat their design as part of the explanation.

Before emitting the page, inspect all five **as a set**, not one at a time.

## Difficulty

- Medium: hard enough that you must have understood the substance of the concept to answer,
  never a gotcha, never trivia.
- Ask about **behavior, causality, invariants, edge cases, and trade-offs**. "What breaks if
  the weighting rule is dropped?" beats "who invented this algorithm?".
- Definitions belong on flashcards, not in the quiz — a question that only checks recall of a
  term wastes one of the five.
- Every answer must be derivable from the page. If it requires knowledge the page never
  gave, either teach it above or drop the question.
- Never a question whose answer is a phrase the reader can pattern-match from a nearby
  paragraph.

## Options

- Four options per question.
- **Order and balance are the engine's job, not yours.** It shuffles the distractors with a
  per-page seed and drops the correct answer into a slot from a seeded permutation of 0–3, so
  the first four questions use every position exactly once. Do not hunt for a lucky `SEED`,
  do not hand-order `options`, and do not try to compensate — `answer` is simply the index of
  the right option in the array you wrote.
- Options comparable in length, grammar, specificity, and confidence. The classic tell is a
  correct answer that is longer, more hedged, and more technically precise than its
  distractors — shorten it or enrich them.
- Every distractor encodes a **real misunderstanding** of the concept — pull them from the
  page's Common misconceptions section: the wrong mental model, the bound that holds only in
  the average case, the step that looks reversible but is not. No joke answers, no impossible
  claims.
- No "all of the above", no "none of the above".

## Feedback

- Reveal feedback only after the reader selects.
- Mark the selected option, state whether it is correct, and explain **why** — the relevant
  invariant, step, or bound, and where useful the misconception the distractor encodes.
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
2. Read the four options of each question aloud. Could you pick the right one without
   reading the page? If yes, rewrite the distractors.
3. Does each question test a different aspect — intuition, the formal statement, the worked
   example, a misconception, a trade-off? Five questions about the same definition is one
   question asked five times.
4. Does at least one question depend on something the reader can only get by **operating a
   figure** — stepping the algorithm, dragging the slider, toggling the two states? If every
   answer is readable off the prose, the figures were decoration after all.

Position balance is not on this list any more: `references/verify.js` checks the rendered
quiz, and the engine guarantees the spread.
