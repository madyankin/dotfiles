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

## 3. No config note? Discover the folder from what is already filed

A vault that has run one of these skills before carries the answer in its own
notes. Look for the pairs they leave — a `.md` whose tags contain `explanation`,
next to an `.html` of the same name — before giving up:

```bash
grep -rl --include='*.md' -e '^  - explanation$' -e 'tags:.*explanation' "$VAULT" \
  | grep -v '/.obsidian/' \
  | while read -r f; do [ -e "${f%.md}.html" ] && dirname "$f"; done | sort | uniq -c | sort -rn
```

Every hit is a folder a previous run chose. Pick the one whose existing notes are
closest **in subject** to what you are about to write — not the one with the most
notes, and not the first line of output. Then **open one sibling note there** and
copy three things from it: frontmatter shape, title language, and whether it
carries `anki-deck`.

Say which folder you picked and which sibling you matched, before writing
anything. Offer once to create the config note, so the next run reads it instead
of rediscovering this.

## 4. Degrade, never guess

No vault, Obsidian not running, or no config note **and** no filed pair to copy →
**produce the HTML only**. Write it where the user asked or to the current
directory, say where it landed and why there is no note. Never stall waiting for
Obsidian, and never fall back to an invented path.
