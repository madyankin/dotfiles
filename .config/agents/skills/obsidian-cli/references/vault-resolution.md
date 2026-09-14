# Resolving the vault and explainer config

Shared by `explain-concept`, `explain-diff` and `explain-german`. None of them
may contain a vault path, a folder name, or a deck name. All of it is
configuration and lives in Obsidian.

## 1. Find the vault

Never type a vault path into a skill, and never invent one.

```bash
VAULT="${OBSIDIAN_VAULT:-$(python3 -c 'import json,os
d = json.load(open(os.path.expanduser("~/Library/Application Support/obsidian/obsidian.json")))
vaults = d["vaults"]
open_vaults = [v for v in vaults.values() if v.get("open")]
print((open_vaults or list(vaults.values()))[0]["path"])')}"
```

`$OBSIDIAN_VAULT` wins when set. Otherwise take the registered vault marked
`"open": true`; fall back to the first registered vault when none is open.

## 2. Read the config note

Each explainer names one MOC note whose frontmatter holds its settings:

| Skill | Config note |
|---|---|
| `explain-concept` | `Explainers` |
| `explain-diff` | `Explainers` |
| `explain-german` | `Deutsch` |

```bash
obsidian read file="Explainers"
```

Recognised keys (values below are illustrative — the real ones live in the note):

```yaml
---
explainer_folder: 3 Resources/Explanations   # where notes and HTML go
explainer_anki_deck: Explanations            # Anki deck, or its parent
explainer_sources: 3 Resources/Books         # optional extra source tier
explainer_subjects:                          # optional folder-per-subject map
  algorithms: 3 Resources/Algorithms
  systems: 3 Resources/Software Development
---
```

Only `explainer_folder` is required. Everything else is optional and the
skill must work without it:

- no `explainer_subjects` → everything goes in `explainer_folder`
- no `explainer_sources` → skip that source tier entirely
- no `explainer_anki_deck` → build the cards, offer them, do not push

## 3. Degrade, never guess

No vault, no config note, or Obsidian not running → **produce the HTML only**.
Write it where the user asked or to the current directory, say where it landed
and why there is no note. Never stall waiting for Obsidian, and never fall back
to a guessed path.
