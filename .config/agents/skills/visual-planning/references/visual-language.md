# Visual language

One small, consistent vocabulary across all pages of one piece of work.

## Status

Three colours carry status everywhere. Do not add a fourth without a reason.

| Token | Meaning on a plan | Meaning on a map |
|-------|-------------------|------------------|
| green (`--have`) | exists, extend it | fact, healthy, new in an option |
| amber (`--build`) | write new | inference, changed in an option |
| red (`--gap`) | missing: decide, then write | problem, loss, removed in an option |
| accent (`--accent`) | question, link, selection | question, link, selection |

Chip text names the action: "extend existing", "write new", "decide, then
write". Never size words. Put a legend under every table that uses chips.

Progress chips: "done · <link>", "partial", "done differently", "rolled back",
"draft", "in progress", "not started". Each "done" links to the change.

## Evidence marks

- **F** fact: seen in code, config, logs or metrics. Give the pointer (`file:line`,
  query, dashboard, sha) and the time it was seen.
- **I** inference: give the facts, the chain, and what would refute it.
- **Q** question: say where to look and what it costs to find out. A question
  without a plan to answer it is noise.

On diagrams: solid line = F, dashed = I, dotted with "?" = Q. Numbers carry a date
and a source; mark recalculated estimates separately from measured values.

## Diagrams

- Draw the mechanism, not a box chart. Label every arrow with what moves.
- Mark where data is lost, slow or wrong. Mark what is not affected.
- Fixed grid. When a diagram has variants (options, before/after), nodes keep
  their positions and only colours and dashes change.
- Inline SVG with `viewBox`, colours from CSS tokens so both themes work. Wide
  SVG sits in an `overflow-x:auto` box with a `min-width`.
- Interactive nodes: `<g data-id tabindex="0" role="button">`, open a side panel
  on click and on Enter.

## Tables

- One metric per column. Numbers right-aligned, `tabular-nums`, mono.
- Scenarios as divider rows, not a column.
- No "conclusion" column. Highlight the winner row; one sentence under the table.
- Wrap each table in `overflow-x:auto` with a `min-width` on the table.

## Words

- Plain words. Short sentences. The user's language.
- Define every term, flag, internal name and ticket ID once. People get a name,
  a role and what they own.
- No identifiers as explanations. "The worker skips rows it already wrote", not
  "idempotent upsert via `ON CONFLICT`" alone.
- Dates are absolute ("2026-10-14"), never "yesterday".

## Page mechanics

- Colour tokens on `:root`, a dark set under `prefers-color-scheme: dark` guarded
  by `:root:not([data-theme="light"])`, and again under `:root[data-theme="dark"]`.
  Explicit `body` background.
- 16px side gutter, no horizontal page scroll at phone width.
- Fonts from Google Fonts with Cyrillic support when the page is in Russian.
- Scripts only from approved CDNs with an exact version, or inline.
- `localStorage` only for viewer conveniences (a filter, a tab), always in
  try/catch. The page must work without it.
- Unique `id`s. A duplicate id makes a script fill the wrong element.
- Counters, filters and tabs read from the DOM or one data object, so an edit in
  one place updates everything.
