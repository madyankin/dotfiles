# Design

The page must look like a well-made product doc, not a lab report. `example.html` implements everything below; copy it rather than rebuilding.

- **Type:** Inter for text, JetBrains Mono for code (Google Fonts); body 16px/1.65; h1 ~2.5rem tight, weight 700; small uppercase eyebrows above headings.
- **Color:** cool neutral background biased toward the accent, white surfaces, one accent (indigo). Green / amber / red only for new / changed / removed and for risks. Light by default; dark tokens under `prefers-color-scheme: dark`.
- **Layout:** sticky table of contents on the left on wide screens; content column ≤ 820px, prose ≤ 68ch; big vertical rhythm between sections.
- **Hero:** eyebrow (ticket key linked · PR number), title = the PR / ticket name verbatim, a lead of ≤ 35 words at ~1.2rem and ≤ 52ch, meta chips, then a row of context tiles (Why wider, terms, Example) that stacks on phones. The hero never holds more than one paragraph of running text.
- **Components:** hero as above; before/after as paired cards with small Before / After labels (muted old → elevated new); an "unchanged" strip; mechanism links as numbered cards; review risks as a collapsed amber callout near the top, count in its summary; diagrams in rounded framed panels with a caption underneath; code steps as file cards (step tag, title, path link in the header, highlighted code, one-line "why" footer); "Proven by" line under each mechanism; inference badge; reference as accordions with count chips.
- **Delta colors on diagrams:** new = green, changed = amber, removed = red and dashed, always with the text mark «new» / «changed» / «removed».
- **Mermaid:** in an Artifact the viewer renders it natively in the viewer's theme; in a local file, `theme: 'base'` with `themeVariables` read from the page's CSS tokens, so diagrams match the palette.
- **Avoid the stock AI look:** no accent bar or rail on rounded cards, no cream background, no gradient hero, no emoji markers, no numbered markers unless the content really is a sequence.
- **Never:** default browser tables for prose, bare bullet lists of fragments, grey boxes around everything, more than one accent color, diagram text below 11px after scaling (shrink the grid before the font).
