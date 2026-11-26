# Optional Obsidian index note

Use only when the user asks for an Obsidian note. Resolve the vault and explainer folder from the user's configuration. Save this Markdown note beside the HTML page. Keep the summary and outcomes readable on mobile without opening the HTML. Do not claim a quiz or Anki cards exist unless the user requested and received them.

```markdown
---
tags:
  - explainer
---

# «Change title»

«One-sentence behavior change.»

[[«matching HTML filename»|Open the HTML explanation]]

| Same input | Before | After |
| --- | --- | --- |
| «input» | «old result» | «new result» |

Source: «repository and exact comparison»
```

Check that the HTML link resolves and the frontmatter parses. Add related wikilinks only when their targets exist.
