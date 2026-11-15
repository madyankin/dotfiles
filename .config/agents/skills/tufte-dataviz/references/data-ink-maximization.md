# Data-ink maximization

Data-ink ratio = ink that displays data / total ink in the graphic.

Data-ink is the non-erasable core: non-redundant ink arranged in response to
variation in the numbers. Maximize within reason. Every element earns its place by
encoding information.

## Workflow

1. **List every element.** Lines (axes, grids, borders, data lines), shapes (bars, points, areas), text (labels, legends, titles, annotations), colors (backgrounds, fills, outlines), effects (shadows, 3D, gradients).
2. **Classify each.**

| Class | Definition | Action |
|---|---|---|
| Data-ink | Directly represents a value | Keep |
| Redundant data-ink | Repeats what is already shown | Remove |
| Non-data-ink | Decoration or structure only | Evaluate |

3. **Erasure test** for each non-data element: remove it; is information lost? No: remove. Yes: it was data-ink, keep. Maybe: try the graphic without it.
4. **Cut redundancy.** Legend + direct labels: keep direct labels. Axis title + self-explanatory tick labels: title usually goes. Gridlines + ticks: one suffices. Border + background color: border goes.
5. **Lighten what stays.** Heavy grid: light gray or dotted. Bold axis: thin gray. Prominent border: subtle or none. Dark background: white or light.
6. **Shrink test.** Shrink the graphic hard. Still readable: good ratio. Illegible: too much non-data-ink.

## Erasure checklist

| Element | Default | Keep only if |
|---|---|---|
| 3D effects | Remove | Never |
| Shadows | Remove | Never |
| Gradients | Remove | They encode a data dimension |
| Background colors | Remove | Essential for grouping |
| Gridlines | Remove | Precise reading is needed |
| Axis lines | Lighten | Data sits near the axis |
| Borders | Remove | Grouping several charts |
| Legends | Replace with direct labels | Direct labels are impossible |
| Data-point outlines | Remove | Points overlap |

## Before and after

- Bar chart. Before: heavy borders, 3D bars, dark grid, legend, gradient background. After: flat bars, direct value labels, no grid, white background.
- Line chart. Before: thick axes, heavy grid, legend box, a marker on every point. After: light gray baseline, no grid, lines labeled at their ends, markers only at key points.
- Dashboard. Before: every widget boxed, navigation chrome, decorative icons, colored backgrounds. After: white, widgets separated by space alone, minimal navigation, no icons.

## Worked example

Input: bar chart of sales by region with gridlines, a border, 3D bars, a legend and axis titles.

Remove: 3D (decoration, distorts perception), border, legend (direct labels instead).
Lighten or drop: gridlines (gone, or very light and dashed); axis titles when the
ticks already read "Q1 … Q4" and "Revenue ($M)".
Keep: bars, tick labels, one baseline.

Result: 2D bars, the value on or above each bar, a light gray baseline, white
background, region names on the x-axis, no legend, border or grid. Shrink test: a
thumbnail still shows the relative heights.

## Limits

Keep what accessibility needs. Gridlines help when precision matters. The goal is
maximum clarity, not minimum elements.
