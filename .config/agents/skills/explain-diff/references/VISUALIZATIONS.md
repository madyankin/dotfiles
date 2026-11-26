# Diagram choices

Notation follows what is drawn: entities in UML, algorithms as flowcharts, processes in BPMN. Every essential path and label must appear in the HTML without JavaScript.

## Entities — UML

| Question | Diagram |
| --- | --- |
| What are the parts and who owns what? | Class diagram: three-compartment boxes (name, fields, methods with `+`/`-`), inheritance as hollow triangle, association as plain arrow, dependency as dashed arrow. Label edges: delegates, persists, renders. Follow with a responsibility table. |
| What states can a record be in? | State diagram: rounded states, filled start circle, ringed end circle, events on transitions, self-loops for "stays open" cases. Say whether state is stored or derived. |
| What changed in a record's shape? | Class box before/after, or a `field | before | after` table. |

## Algorithms — flowchart

One call or function, branch by branch.

- Terminator (stadium) for start and end, rectangle for a step, diamond for a decision, parallelogram for input/output.
- Decisions phrased as questions; every outgoing edge labeled Yes/No or the value.
- Merge error exits into one end node. Show rollback and commit as distinct steps.
- Old vs new on one path: two flowcharts side by side, same input, changed step marked in words.

## Processes — BPMN

Work across actors over time: human, agent, MCP client, UI, server, DB, background job.

- One pool per participant system or organization; lanes for roles inside it.
- Thin circle start event, thick circle end event, double-ring intermediate event (timer for TTL, message for a callback).
- Rounded rectangle tasks named verb + object.
- Gateways as diamonds: `×` exclusive, `+` parallel. Label each outgoing flow.
- Solid arrows for sequence flow inside a pool; dashed arrows with an open circle tail for message flow between pools, labeled with the call (`tools/call`, `create_campaign`).
- Concurrency: two lanes of the same request type meeting at the lock; the waiting lane shows an intermediate event until the lock is released.
- Trust boundary: put what each party receives on the message flow (payload with or without key); add a "who sees what" table if the flow gets crowded.

## Other

| Content | Form |
| --- | --- |
| Value derivation | Small data-flow: inputs → function → output, e.g. token + server secret → HMAC → key. |
| Rename or extraction | Two-column mapping; do not invent runtime behavior. |
| Measured performance | Table with units and source; chart only for real data. |

## Drawing rules

Place each figure right before the code it explains, with a caption naming the one thing to notice. Label arrows and branches in text; never rely on color or position alone. Abbreviate long class names in the figure and say so in the caption. At narrow widths stack panels and let wide SVG scroll horizontally. Use a table when connector lines would obscure the path.

Draw as inline SVG (`viewBox`, `width="100%"`, `currentColor`, CSS variables for accent). Define arrowheads once in `<defs>` as markers: filled for sequence flow, open triangle for inheritance, open circle tail for message flow. Give each SVG a `<title>` or `aria-label`. Keep the same information available as text near the figure.

Reuse the shared input across diagrams, tables, and code. Label any different input as its own scenario. Never show a possible branch as the one taken. If the source does not establish a transition, mark it unverified rather than completing the picture from intuition.

Native `<details>` may hold extra traces or a larger evidence table. Core idea, mechanism diagrams, and literate steps stay visible with every section closed.
