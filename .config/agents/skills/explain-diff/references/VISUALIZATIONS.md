# Static diagram choices

Choose the smallest diagram that makes the behavior visible. Every essential path and label must appear in the HTML without JavaScript.

| Change | Useful static form |
| --- | --- |
| Request path or algorithm | Two ordered flowcharts, before and after, with the same input and labeled branches |
| Changed condition | Decision box with both outcomes, and the taken branch marked in words |
| State transition | Two state diagrams or a transition table with named states and events |
| Data structure | Before/after nodes or a compact table of keys and values |
| Rename or extraction | Two-column mapping; do not invent runtime behavior |
| Measured performance | Small table with units and measurement source; chart only if it helps compare real data |

Place the figure beside the behavior it explains. Put a caption under it naming the important change. Label arrows and branches in text; do not rely on color or position alone. At narrow widths, stack before and after while preserving their headings. Use a table when connector lines would obscure the path. A static inline SVG is acceptable if its labels remain legible and the same information is available as text; CSS and semantic HTML are usually simpler.

Use the same concrete input across diagrams, outcome table, and code explanation. If an edge case requires a different input, label it separately. Never show a possible branch as the branch actually taken for the example. If the source does not establish a transition, mark it unverified rather than completing the picture from intuition.

Native `<details>` may hold additional traces, assumptions, or a larger evidence table. The main before/after behavior stays visible when every section is closed. JavaScript enhancements are optional and may only duplicate, not replace, essential information.
