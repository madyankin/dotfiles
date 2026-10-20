# Graphical integrity audit

"Graphical excellence begins with telling the truth about the data."

Lie factor = size of effect shown in the graphic / size of effect in the data.
1.0 is perfect. 0.95–1.05 is acceptable. Above 1 exaggerates; below 1 understates.

## Six principles

1. **Proportional representation.** If A is twice B, A's mark is twice as large.
2. **Clear labeling.** Every element labeled; the viewer can read the data back from the graphic.
3. **Data variation, not design variation.** Visual interest comes from the numbers, not the styling.
4. **Standardize money.** Time series of money use deflated, constant currency.
5. **Context.** No out-of-context quoting; show the relevant comparison.
6. **Source transparency.** Cite the data. Make it checkable.

## Workflow

1. **Compute the lie factor.** Data change = (B − A) / A. Visual change: bars by height or length; areas by area, not diameter; 3D after checking perspective. Lie factor = visual % / data %.
2. **Check common distortions.**

| Distortion | Detect | Severity |
|---|---|---|
| Truncated axis | y-axis does not start at zero | High |
| Inconsistent scale | Axis intervals vary | High |
| Area or volume for 1D data | Circles, cubes for linear values | High |
| Dual axes | Two y-axes, different scales | Medium |
| Cherry-picked range | Period chosen to fit the narrative | High |
| Missing data | Gaps unacknowledged | Medium |
| 3D perspective | Relative sizes distorted | High |

3. **Verify context.** Fair comparison? Representative period? Relevant comparisons shown? Appropriate baseline? Outliers acknowledged?
4. **Check source and labels.** Source cited? Verifiable? All elements labeled? Units given? Date and time clear?

## Distortion patterns

- **Truncated y-axis.** A stock moving $98 to $102 (4%) on an axis $96–$104 reads as a ~75% visual rise. Lie factor 18.75. Fix: start at zero, or mark the break clearly.
- **Area or volume inflation.** Doubling a circle's diameter for a 2× value makes the area 4× and the perceived volume 8×. Lie factor 4–8. Fix: use length (bars, lines).
- **Cherry-picked timeframe.** Trough to peak. Ask: why this start, why this end? Fix: a longer span with context.
- **Dual-axis deception.** Two unrelated scales side by side imply correlation (ice cream sales vs drownings). Fix: normalize, or separate charts.

## Integrity score

| Grade | Criteria |
|---|---|
| A Excellent | Lie factor 0.95–1.05, no distortions, full source |
| B Good | 0.8–1.2, minor issues, source present |
| C Acceptable | 0.5–2.0, some distortions, partial context |
| D Poor | Outside 0.5–2.0, multiple distortions |
| F Deceptive | Intentional distortion, missing or false source |

## Worked example

Input: customer satisfaction 3.8 → 4.2 on a 5-point scale; the y-axis runs 3.5–4.5.

Data change: (4.2 − 3.8) / 3.8 = 10.5%.
Visual: axis range 1.0; 3.8 sits at 30% of the axis, 4.2 at 70%; 70 − 30 = 40 points,
a 133% rise from the starting visual height.
Lie factor: 133 / 10.5 = 12.7. Grade D.
Distortions: truncated axis (High); compressed scale (the 1–5 scale shown as 3.5–4.5).
Fixes: axis 1–5 (the change stays visible, correctly sized); or an explicit axis break
with full context beside it; or state it in text: "3.8 → 4.2, +11%".

## Limits

Not every truncated axis lies. Log scales can be honest. Intent matters for ethics,
not for perception. Conventions differ by culture.
