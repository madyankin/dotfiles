# The Obsidian note

The note follows the same budget as the HTML (see `explainer-spec.md`): the same compressed
wording, the same mnemonics, and diagrams described in a single line of prose ("what it shows and
what changes"). Do not expand in the note what you compressed in the HTML.

The note is an **optional** second version of the explainer: it is read on a phone, it enters search
and the graph, and the Anki cards come from it. The HTML stands alone and is always written; the
note appears only if the user chose it in the current run, the vault is configured, and Obsidian is
running. When the choice is "HTML only", do not touch the vault at all.

## The config lives in the vault

The skill stores neither the vault path nor the output folder. All of it is in the frontmatter of
the `Deutsch` note (the area MOC), so it is edited directly in Obsidian without touching the skill,
and syncs between machines along with the vault:

```yaml
---
tags: [deutsch]
explainer_folder: 2 Areas/Deutsch/Explainers
explainer_anki_deck: Deutsch
---
```

| Key | What it sets | If absent |
|---|---|---|
| `explainer_folder` | vault folder for the note and the HTML | no note is written, only the HTML |
| `explainer_anki_deck` | Anki deck for the cards | cards stay in the note, do not offer to push |

### Resolution

Follow `obsidian-cli/references/vault-resolution.md`, reading the config from the `Deutsch` note.
No vault, no `Deutsch` note, no key, or Obsidian not running → **HTML only**. Put it where the user
asked, otherwise in the current directory, and say where it is and why there is no note. Never
invent a vault path and never wait for Obsidian to start.

## Paths

```
<explainer_folder>/YYYY-MM-DD — <Thema>.md
<explainer_folder>/<slug>.html
```

- The folder is created on first run (`obsidian create` does it itself).
- The HTML sits **next to** the note, not in `_Support/Attachments`: a relative link survives syncing
  between machines, an absolute `file://` does not.
- `<Thema>` in the note name is human, with spaces and umlauts. `<slug>` is ASCII, kebab-case, with
  the date in front: `2026-09-13-wechselpraepositionen`. The same `slug` goes into `DATA.meta.slug`
  (the localStorage key for the quiz result).
- `path=` in `obsidian` commands is assembled only from `explainer_folder` and these literals —
  never from OCR text, a web page, or note contents.

### Duplicate protection

Before `obsidian create`, search for the exact name and the topic. If there is no note, create it.
If an explainer on the same topic exists, do not overwrite it and do not silently create a second
file: ask whether to extend the existing note or create a narrower one with the topic qualified in
the name. If extending is chosen, read the existing note first and preserve its links and
frontmatter. An identical HTML slug counts as a collision too: pick a qualified slug before building.

## Frontmatter

```yaml
---
tags: [deutsch, explainer]
niveau: B1
thema: Wechselpräpositionen
quelle: "Menschen A2, S. 44 (фото)"
modus: grammatik
erstellt: 2026-09-13
---
```

`quelle` is where the material came from: textbook name with page, a URL, "свои ошибки из чата".
If the source is a link, use the full URL so it can be revisited.

## Body

The note is written in Russian — these headings are the output, not labels to translate.

```markdown
[▶ Интерактивная версия](2026-09-13-wechselpraepositionen.html)

> Разбор к [[Deutsch]]. Уровень: B1.

## Зачем
…

## Интуиция
…

## Мнемоника
- …

## Что надо помнить
…

## Разбор
…

## Грабли
…

## Квиз
1. …
   ?
   **Ответ:** …

```

## Cards

The only flashcard mechanism is **Anki via the `anki-cards` skill** (MCP). No plugin syntax in the
note: no `#card`, no `::`, no `:::`. The note holds the cards as an ordinary readable list — a
source of truth for a human, not for a parser.

```markdown
## Карточки

- Какие девять предлогов — Wechselpräpositionen? → an, auf, hinter, in, neben, über, unter, vor, zwischen
- Какой вопрос выбирает Akkusativ? → Wohin? — есть перемещение
- die Entscheidung, -en → решение
```

- **The deck comes from `explainer_anki_deck`.** Do not create per-topic subdecks and do not ask
  every time where to put them. If the deck does not exist, `anki-cards` creates it (`create_deck`).
  Topic and level live in tags, not in the deck tree.
- **Tags:** `deutsch`, `explainer`, the topic in kebab-case (`wechselpraepositionen`), the level
  (`a2`) and the mode (`grammatik`). These are what later filtering and repair work from.
- Card quality follows the `anki-cards` skill's rules (one fact per card, shortest possible answer).
- Nouns always carry their article and plural.
- Pushing is a separate step: hand the cards to `anki-cards`, **only after explicit user consent**.
  The model (Basic/Cloze) is chosen by `anki-cards`; do not duplicate that logic here.
- If Anki is not running, say so — the cards stay in the note and can go up later.

## Write commands

HTML via the `Write` tool. The note via the CLI (see the `obsidian-cli` skill), using `\n` instead
of real line breaks:

```bash
obsidian create name="2026-09-13 — Wechselpräpositionen" \
  path="<explainer_folder>/2026-09-13 — Wechselpräpositionen.md" \
  content="---\ntags: [deutsch, explainer]\n…" silent
```

Check after writing:

```bash
obsidian read file="2026-09-13 — Wechselpräpositionen"
```

If `obsidian` does not respond, Obsidian is not running. That is a normal situation, not a failure:
save the HTML, tell the user there will be no note, and offer to create it once the app is up. Do
not retry blindly.

## What requires explicit consent

The vault rule (`AGENTS.md`, Safety Rules) — never change anything in external systems silently:

- appending words to `Mein Wörterbuch.md`;
- pushing cards to Anki;
- editing `Deutsch.md` or any existing note.

Once the user has explicitly chosen "HTML and an Obsidian note" in the current run, creating a new
note in `explainer_folder` is already authorised and needs no second confirmation. Editing the
`explainer_*` keys in `Deutsch.md` does.
