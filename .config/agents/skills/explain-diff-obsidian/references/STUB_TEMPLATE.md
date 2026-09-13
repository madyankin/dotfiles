# Markdown stub template

The stub is what Obsidian actually indexes: search, graph, backlinks, and mobile all read
this file, not the HTML. Keep it standalone-useful — a reader who never opens the HTML should
still get the summary and the takeaways.

File name matches the HTML exactly, `.md` instead of `.html`.

```markdown
---
title: «Title, same as the HTML page»
created: «YYYY-MM-DD»
tags:
  - explanation
  - code
  - «repo-name»
source: «PR URL, branch name, or commit range»
repo: «org/repo»
anki-deck: Explanations::Code
---

> [!tip] «Открыть explainer» → [[«YYYY-MM-DD slug».html|«Title»]]
> «В браузере квиз кликабельный; внутри Obsidian — только чтение.»

## «Кратко»

«5–10 строк: что изменилось, зачем, и на что это влияет. Достаточно, чтобы через месяц
вспомнить суть, не открывая HTML.»

## «Главное»

- «Takeaway worth remembering in a month.»
- «…»
- «…»

## «Связано»

- [[«Existing vault note»]] — «why it is related»
- [[«Another note»]]

## «Карточки»

«Отправлено в Anki, колода `Explanations::Code`, тег `«slug»`:»

- «Front of card» → «Back of card»
- «Front of card» → «Back of card»
```

## Rules

- **Link to the HTML** with a wikilink (`[[2026-09-13 slug.html]]`) — Obsidian resolves
  non-markdown files by name and opens them in the default app. A relative Markdown link
  works too; the wikilink survives renames.
- **Cards go to Anki through the MCP**, handled by the `anki-cards` skill. The `«Карточки»`
  section here is a human-readable record of what was pushed, not a sync source. Use `→`,
  never `:::` — the `flashcards-obsidian` plugin is installed and would pick up `:::` lines
  and create a second copy of every card.
- **`anki-deck`** in frontmatter records where the cards went, so a later run can find and
  extend them instead of duplicating.
- **Wikilink only to notes that exist.** Search first; a red link in the graph is noise.
- **Language** follows the request: Russian ask → Russian headings, with code, identifiers,
  and technical terms left in English.

## Example (filled)

```markdown
---
title: TTL-кэш для bidder-ответов
created: 2026-09-13
tags:
  - explanation
  - code
  - dsp-core
source: https://github.com/remerge/dsp-core/pull/4821
repo: remerge/dsp-core
anki-deck: Explanations::Code
---

> [!tip] Открыть explainer → [[2026-09-13 bidder-ttl-cache.html|TTL-кэш для bidder-ответов]]
> В браузере квиз кликабельный; внутри Obsidian — только чтение.

## Кратко

Ответы bidder'а кэшировались бессрочно, поэтому изменения таргетинга применялись только
после рестарта. Теперь у записи есть TTL, а вытеснение ленивое: запись живёт до первого
обращения после истечения. Экономия RPS сохраняется, задержка применения ограничена TTL.

## Главное

- Вытеснение ленивое, не по таймеру — expired-запись занимает память до следующего чтения.
- TTL=0 отключает кэш целиком, а не делает его однократным.

## Связано

- [[Кэширование в DSP]] — общий обзор слоёв кэша

## Карточки

Отправлено в Anki, колода `Explanations::Code`, тег `bidder-ttl-cache`:

- Когда expired-запись освобождает память в bidder-кэше? → При первом обращении к ключу после истечения TTL, не по таймеру
- Что означает `ttl = 0` в конфиге bidder-кэша? → Кэш выключен полностью
```
