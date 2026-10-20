# Small multiples design

"Once viewers understand the design of one slice, they have immediate access to the
data in all the other slices." The eye compares instantly. Patterns emerge without
explanation. No animation needed: repetition with variation.

## Workflow

1. **Pick the comparison dimension.** Time (months, years, decades); geography (countries, regions, stores); category (products, departments, segments); condition (before/after, treatment groups); variable (different metrics on one scale).
2. **Design one base panel** that works on its own: simple structure, consistent scale and axes, minimal non-data ink. Every panel then uses identical scale, axes and encoding. Only the data changes.
3. **Choose the layout.**

| Layout | Best for |
|---|---|
| Rows | Sequential comparison (time, process) |
| Grid | Many categories with no implied order |
| Wrapped rows | Ordered categories wider than one row |
| Trellis | Two dimensions (rows × columns) |

4. **Repeat.** Same size, same scale, same encoding, different data.
5. **Label.** Short panel label (year, region, category) in a consistent position. No repeated axis labels after the first panel.
6. **Arrange for comparison.** Related panels adjacent. Meaningful order: chronological, alphabetical, by value. Optionally highlight one reference panel.

## Rules

- **Scale consistency is mandatory.** Different y ranges: comparison impossible. Different x ranges: misleading patterns. Different color scales: false equivalence.
- **Panel size.** Large enough to read, small enough to see many at once. Test: is the pattern visible at arm's length?
- **White space.** Clear separation, consistent gutters, no borders unless grouping is needed.
- **Labeling efficiency.** First panel labeled fully; the rest identified only; shared axes labeled once at the edge.

## Classic cases

Muybridge's motion studies (1878): same framing, sequential frames; showed all four
hooves off the ground. Periodic table: one format per element, position encodes
properties. Election maps by year: same geography and colors, different years.
Sparkline rows: one metric per entity, small multiples inside a table.

## Worked example

Input: temperature patterns across 12 months for 4 cities.

Base panel: daily high/low area chart for one month; x = days 1–31; y = one shared
range (e.g. −10°F to 110°F) for every panel.
Layout: trellis, 4 rows (cities) × 12 columns (months). City labels on the left,
month labels on top, y ticks only in the leftmost column.
Read-out at a glance: Miami flat year-round; Phoenix spikes July–August; Seattle in
narrow bands; NYC four seasons. 48 panels, one glance, no animation.

## Limits

Needs enough data per panel. Works best with 4–50 panels: fewer, overlay them
instead; more, it becomes noise. Print and static beat screens for many panels.
