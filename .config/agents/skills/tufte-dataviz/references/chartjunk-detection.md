# Chartjunk detection

Chartjunk: any visual element that does not help the viewer understand the data,
and often impedes it. "Chartjunk has the effect of making the clear unclear."

## Checklist

| Category | Element | Problem | Severity |
|---|---|---|---|
| Dimensional distortion | 3D effects on 2D data | Distorts proportions, adds nothing | High |
| | Perspective views | Back elements look smaller than front | High |
| | Tilted axes | Distorts comparison | High |
| | Exploded pie slices | Breaks proportional reading | Medium |
| Visual noise | Moiré patterns | Vibration from tight hatching | High |
| | Heavy gridlines | Compete with data | Medium |
| | Decorative borders | Frame carries no information | Low |
| | Background textures | Noise behind signal | Medium |
| Gratuitous decoration | Clip art, icons | Decoration posing as data | High |
| | Illustrations | Replace or cover data | Medium |
| | Drop shadows | Weight without meaning | Low |
| | Gradient fills | Decoration, rarely data | Medium |
| Redundancy | Legend + direct labels | Same information twice | Medium |
| | Color + shape + pattern for one variable | Triple encoding | Low |
| | Axis title stating the obvious ("Time") | Redundant | Low |
| | Same label repeated on every element | Noise | Medium |
| Self-promotion | Large logos | Branding over communication | Medium |
| | "Designed by" credits in the data area | Noise | Low |
| | Decorative typography | Style over readability | Medium |
| | Brand color schemes | Not tuned for data | Medium |

## Workflow

1. Inventory every visible element: lines, shapes, colors, text, effects, backgrounds, frames.
2. Test each one. Represents data: keep. Helps read the data: keep, consider lightening. Adds nothing: candidate for removal. Obscures data: remove now.
3. Score the whole graphic.

| Score | Meaning |
|---|---|
| 0 Clean | Data-forward, minimal decoration |
| 1 Light | Minor unnecessary elements |
| 2 Moderate | Noticeable decoration, does not impede |
| 3 Heavy | Decoration competes with data |
| 4 Severe | Decoration obscures data |
| 5 Junk | More junk than data |

4. Fix in order: distorts (3D, perspective) > obscures (moiré, heavy patterns) > competes (decoration, heavy grids) > redundant (duplicate encodings) > merely unnecessary (borders, backgrounds).

## Magazine-cover test

Does it look like a business magazine trying to seem data-driven (dramatic angles,
bold decorative colors, illustrations beside the data, "infographic" style), or like
a statistical journal presenting data (orthogonal views, functional color, data only)?

## Worked example

Input: 3D pie, 8 slices, gradient fills, decorative border, legend with company logo.

Severity 4/5.

| Element | Class | Issue |
|---|---|---|
| 3D effect | Junk, High | Front slices read larger than their share |
| Pie with 8 slices | Structural | Eye fails past ~5 angle comparisons |
| Gradient fills | Junk, Medium | Encode nothing |
| Border | Junk, Low | Adds nothing |
| Separate legend | Redundant | Eye jumps back and forth |
| Logo | Junk, Medium | Self-promotion in the data area |

Fixes, in order: 2D, better a bar chart (eight categories are too many for a pie);
flat colors; direct labels instead of the legend; drop the border; move the logo out
of the data area or drop it.

Alternative: horizontal bars ordered by value, value labels on the bars, no
gridlines, flat accessible colors, no border, no logo in the data area.

## Limits

Legitimate branding exists. Marketing tolerates what a statistical report does not.
Match audience expectation. Good design is not no design.
