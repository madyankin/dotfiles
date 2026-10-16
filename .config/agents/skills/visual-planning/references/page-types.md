# Page types

Each recipe lists sections in order. Drop a section that has no content. Do not
pad. Every page ends with a footer: source docs (full paths), commit SHAs or refs
read, the research date, and "page and doc are updated together".

## Plan map — exists / build / missing

Use for: a feature or project that spans several components, after research.

1. **Header.** Eyebrow (ticket or project, research date). Title. One-sentence lede.
   Refs line (`repo@sha` per repo). Stat counters: have / build / missing /
   open decisions. Compute the counters in JS from the items, never by hand.
2. **Path.** Numbered step cards `S1..Sn` in real execution order (data or user
   journey order, not repo order). Each card: component tag, status chip, one
   line of what happens, refs to the questions that block it (`Q3`). A missing
   step has a dashed red border.
3. **How it works today.** A mechanism diagram (SVG or CSS grid of boxes). Mark
   the spot where data is lost, slow or wrong in red. Label every arrow.
4. **Contracts** (when components talk). Diagram whose arrows carry contract
   numbers, green for existing, amber for new. Under it a table: contract,
   producer, consumer, change, kind chip.
5. **Detail tables** as the work needs them: fields needed / skip, mockup vs
   backend (yes / partial / no), guardrails, worked example with real numbers.
6. **Rejected options.** One card each: what, why not (cost, ownership, risk).
7. **Questions to people.** Sent vs not asked yet. A draft message with a Copy
   button.
8. **Inventory.** One column per component, each with have / build / missing
   groups. Each item carries a `file:line` pointer. Filter buttons by status
   (`aria-pressed`); remember the filter in `localStorage` inside try/catch.
9. **Decisions.** Numbered `Q1..Qn`. Each says which step it blocks. When solved:
   "Decided <date>: <answer>" in place. A separate short "Open" list at the end.

## Sub-task page

Use for: one sub-task of a plan map that has its own steps and decisions.

1. Header with the task chain: sibling tasks as chips (done / in progress / not
   started), owner, this task highlighted. Link back to the parent map.
2. Step cards with phase tag, status chip and `file:line` anchor.
3. Rules as a "ladder" table when the logic is ordered: condition → result,
   "first match wins".
4. Split panels when there are two audiences: "what the user sees" vs "what goes
   to the log". Keep sensitive values out of the log panel.
5. Code layout table: file → what it is → what it does, plus a 3-line usage snippet.
6. Exists / missing table with status column.
7. "Decided <date>" list, then "Open" list.

## System map — state, flows, boundaries, pressure

Use for: "visualize the architecture of X", "where does the data go", "find the
weak spots". Mental model — a map for a fire brigade:

- **State**: where the data lives (stores, caches, indexes, queues).
- **Flows**: how it moves (pipes, direction, who pushes, who pulls).
- **Boundaries**: what fails together, what is one transaction, who owns which zone.
- **Pressure**: sync vs async, where a burst hits at once, where a queue absorbs it.

Every line and claim has an evidence mark. A map with marks beats a detailed map
without them.

1. **KPI strip.** 4-6 measured numbers, each with source, time window and F mark.
2. **Flow map.** SVG. Zones as tinted bands (ownership and failure domains).
   Node shapes by kind (store, queue, service, outside world). Line style shows
   evidence (solid F, dashed I, dotted Q). Line colour shows timing (sync, async,
   batch). Feedback loops thick. Problem pins (`R4`) on nodes link to the register.
   Each node is `<g data-id tabindex="0">`; click opens a panel with five answers:
   mechanism, cost, boundary, trade-off, evidence.
3. **Named routes.** 3-7 real paths traced through the map ("user pauses X").
4. **Step / failure table.** Step, what it does, where state lives after it, what
   happens if the process dies right after it. Most correctness bugs show here.
5. **Runtime and deploy.** Where it runs, how many instances, locks, rollout.
6. **One real case** as a timeline: waiting grey, work blue, loss red.
7. **Cost model.** Formula, assumptions marked I, a worked example.
8. **Problem register `R1..Rn`.** Problem, evidence, effect, weight, can change
   (yes / careful / no), category filter, status chip.
9. **Where docs differ from code.** Docs say intent, code says what can happen,
   production says what did happen.
10. **What we cannot change.** External contracts, shared resources, hot paths.
11. **Open questions.** Each says where the answer is and what it costs to get.

## Options — compare target designs

Use for: "suggest alternatives", "what can we refactor", "is X worth it".

1. Goal sentence.
2. **2-4 root causes**, each mapped to register IDs. Judge every option by these.
3. **Quick fixes** table: #, change, where, removes which R, expected effect with
   F/I/Q mark.
4. **One diagram, fixed node positions, a tab per option** (Now / A / B / C).
   Green = new, amber = changed, red dashed = removed. Caption per tab. Drive the
   tabs from one config object so nodes never jump.
5. **Option cards.** Mechanism, cost, risk, ownership boundary, when to choose it,
   module or file tree.
6. **Coverage matrix** R × option: ✓ removes, ◐ partly, — no effect, ✗ worse. Add
   cost and risk rows.
7. **Recommended path** with a measurable decision gate ("if p95 stays above N,
   take B"). Say when the cheapest option is a prerequisite for the others.
8. **Invariants** every option keeps.

## Evidence — measurement or diagnosis

Use for: benchmarks, "why do these numbers disagree", "does this give us anything".

1. **Verdict first.** Tiles with one-line claims, then the answer in two sentences.
2. If a later result reversed an earlier recommendation: dated callout.
3. **Comparison table.** Rows = scenarios (divider rows), columns = one metric
   each, numbers right-aligned in mono, inline bars as share of the worst value.
   Highlight the winner row and add one sentence under the table. Mark cells
   still running as "measuring". Include today's baseline and every option
   discussed, on realistic input.
4. For a diagnosis: topology with the slow hop in red and the missing arrow
   named; timeline with the onset marker; checks that the signal is real (check,
   query, value); "what moved" vs "what did not move"; ranked open leads.
5. Before / after on real production cases.
6. Fixes / does not touch, by register ID.
7. Limits and method: what was measured, how, what was not.
8. Draft reply for the thread, when there is one.

## Concept explainer

Use for: "explain for a beginner", "what is this and why".

1. "In short" box and 3-4 big-number tiles.
2. Situation in two sentences.
3. Terms from zero, with one everyday analogy.
4. Mechanism diagram with the hot path highlighted and `file:line` per step.
5. Chart of the real signal with dates of changes annotated.
6. Options with status chips (in progress / idea).
7. "Not verified" notes.

For a single concept inside a chat, an inline interactive widget can be enough:
a slider or toggle, preset cases, a "things to try" list, and stated
simplifications ("made-up noise", "threshold chosen by me").
