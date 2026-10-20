# Sparkline integration

"Data-intense, design-simple, word-sized graphics." A sparkline is a word: trend,
volatility, seasonality and current position in less space than a sentence, without
breaking the flow of the text.

## Design parameters

- **Size.** Height 1–2× the cap height of the surrounding text. Width ~10–40 characters, proportional to data density. Baseline aligned with the text or the table cell.
- **Resolution.** At least 10–20 points; fewer is a symbol, not a sparkline. No upper limit; hundreds work.
- **Simplicity.** No axes, usually no labels, no grid, one color plus highlights. Just the line or the bars.

## Types

| Type | Best for | Structure | Highlights |
|---|---|---|---|
| Line | Continuous trends, time series | One path | Dots at first, last, min, max or current |
| Bar | Discrete periods, when zero matters | Vertical bar per value | Color above vs below baseline |
| Win/loss | Binary outcomes, above/below threshold | Equal-height bars, up or down | Color per outcome |
| Bullet | Performance vs target | Bar with reference lines | Value bar on gray range bands |

## Workflow

1. **Context.** Running text: baseline-aligned, x-height to cap-height. Table cell: fill the width, same height across rows. Dashboard: slightly larger, minimal labels allowed. Margin note: wider, still compact.
2. **Data range.** 20+ points. A relevant window (last 12 months, last 52 weeks). The same window for every sparkline in the document.
3. **Type.** Trend: line. Discrete comparison: bar. Binary: win/loss. Progress vs target: bullet.
4. **Highlights.** Current or last value: dot or text. Min and max: colored dots. First: lighter dot. Target: horizontal reference line.
5. **Scale.** Shared when comparing magnitudes across rows. Individual when each row's own pattern matters; then hint magnitude with subtle shaded bands.
6. **Place.** Align baselines, keep spacing consistent, do not crowd.

## Patterns

Table:

```
Region     Q1 Rev   Trend        YoY
Northeast  $12.3M   ▁▂▃▄▅▆▇█▆▅  +14%
Southeast  $8.7M    ▅▆▇█▇▆▅▄▃▂  -22%
Midwest    $10.1M   ▃▄▄▅▅▆▆▇▇█  +31%
```

Text: "Sales have been rising steadily ▁▂▃▅▆▇ reaching $1.2M last quarter."

Records: one sparkline per measure beside its current value, e.g. vitals over the
last 24 hours.

## Worked example

Input: a table of 50 products with inventory and status; add context without bloating it.

Add a "Last 12 weeks sales" bar-sparkline column between inventory and status:

```
Product    Inventory   Last 12 weeks   Status
Widget A   1,234       ▃▄▅▆▇█▇▆▇▇█▇    In Stock
Widget B   89          ▇█▇▆▅▄▃▂▁▁▁▂    Low Stock
Widget C   2,891       ▄▄▄▄▅▄▄▅▄▄▄▄    In Stock
```

Decisions: bar type (weekly periods); individual scale per row (pattern over
magnitude); no highlights; width 12 characters, one per week. Read-out: A rising, B
collapsed, C steady. No labels, axes or explanation needed.

## Implementation

Excel (built in since 2010), Google Sheets `SPARKLINE()`, Tableau calculated fields,
HTML via SVG or canvas, Unicode blocks `▁▂▃▄▅▆▇█` for plain text. Unicode gives 8
levels; real sparklines give hundreds.

## Limits

Needs sequential data; under 10 points shows no pattern. Shared scales flatten
low-value rows. Provide text alternatives for screen readers.
