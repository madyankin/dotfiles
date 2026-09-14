# Markdown stub template

The stub is what Obsidian indexes: search, graph, backlinks, and mobile read this file, not
the HTML. It is also the note that will sit in `3 Resources/` for years, so it must stand on
its own — summary, takeaways, and the key formulas, not just a link.

Unlike the HTML page, the stub is ordinary Markdown, so real LaTeX works here
(`obsidian-latex-suite` is installed): use `$…$` and `$$…$$` freely.

File name matches the HTML exactly, `.md` instead of `.html`.

```markdown
---
title: «Concept name»
created: «YYYY-MM-DD»
tags:
  - explanation
  - «subject»
subject: «algorithms | os | math | physics | networks | …»
sources:
  - «Book, chapter/section»
  - «Lecture or paper»
anki-deck: Explanations::«Subject»
---

> [!tip] «Открыть explainer» → [[«Concept name».html|«Concept name»]]
> «В браузере квиз и интерактивные фигуры работают; внутри Obsidian — только чтение.»

## «Кратко»

«5–10 строк: что это, какую задачу решает, и какая главная идея. Достаточно, чтобы через год
вспомнить суть, не открывая HTML.»

## «Ключевое»

- «Statement, bound, or invariant — with the formula: $O(\alpha(n))$»
- «Takeaway worth remembering»
- «The trade-off»

## «Нужно знать заранее»

- [[«Prerequisite note»]] — «what it covers»
- «Gap: нет заметки про «X» — читать «source»»

## «Связано»

- [[«Related vault note»]] — «how it relates»

## «Карточки»

«Отправлено в Anki, колода `Explanations::«Subject»`, тег `«slug»`:»

- «Front of card» → «Back of card»
- «Front of card» → «Back of card»
```

## Rules

- **Link to the HTML** with a wikilink (`[[Concept name.html]]`) — Obsidian resolves
  non-markdown files by name and opens them in the default app. The wikilink survives renames.
- **Cards go to Anki through the MCP**, handled by the `anki-cards` skill. The `«Карточки»`
  section is a human-readable record of what was pushed, not a sync source. Use `→`, never
  `:::` — the `flashcards-obsidian` plugin is installed and would pick up `:::` lines and
  create a second copy of every card.
- **Nothing pushed yet?** Then the section says so, rather than silently vanishing or
  claiming cards that do not exist:

  ```markdown
  ## Карточки

  > [!todo] Не отправлено
  > Колода `Explanations::«Subject»`, тег `«slug»` — предложено «N» карточек, ждут подтверждения.
  ```

  Replace that block with the `front → back` list the moment `anki-cards` actually pushes.
  A stub that lists cards nobody created is worse than a stub with no card section.
- **`anki-deck` and `sources`** in frontmatter make a later run able to extend rather than
  duplicate.
- **Prerequisite gaps go in the stub, not only in the HTML.** A gap the reader can see is a
  reading list; a gap hidden in an HTML file is a surprise.
- **Wikilink only to notes that exist.** Search first.
- **One Mermaid diagram** carrying the single structural idea, so the note teaches something
  on mobile without opening the page. Obsidian renders Mermaid natively. Keep it under ~10
  nodes; it is a summary, not a second copy of the page's figures.
- **Title and headings match the folder's language.** `3 Resources/Algorithms/` is
  Russian-titled; a lone English note there is a wart.

## Example (filled)

```markdown
---
title: Сжатие пути в Union-find
created: 2026-09-13
tags:
  - explanation
  - algorithms
subject: algorithms
sources:
  - Sedgewick, Algorithms 4ed, §1.5
  - Tarjan 1975, "Efficiency of a Good But Not Linear Set Union Algorithm"
anki-deck: Explanations::Algorithms
---

> [!tip] Открыть explainer → [[Сжатие пути в Union-find.html|Сжатие пути в Union-find]]
> В браузере квиз и интерактивные фигуры работают; внутри Obsidian — только чтение.

## Кратко

`find` проходит по дереву до корня. Сжатие пути переподвешивает все пройденные узлы прямо к
корню, поэтому следующий `find` по тем же узлам стоит O(1). Вместе с объединением по рангу
даёт амортизированную стоимость $O(\alpha(n))$ — практически константу.

## Ключевое

- Амортизированная стоимость операции: $O(\alpha(n))$, где $\alpha$ — обратная функция
  Аккермана; для любого реального $n$ это ≤ 5.
- Сжатие пути само по себе (без рангов) даёт $O(\log n)$ амортизированно — нужны оба приёма.
- Сжатие меняет форму дерева, но не множества: корень и принадлежность компоненте те же.

## Нужно знать заранее

- [[Задача о динамической связности]] — зачем вообще Union-find
- [[Взвешенное быстрое объединение в Union-find]] — объединение по рангу

## Связано

- [[Поиск кратчайшего пути]] — Kruskal использует Union-find

## Карточки

Отправлено в Anki, колода `Explanations::Algorithms`, тег `union-find-path-compression`:

- Что делает сжатие пути при вызове `find`? → Переподвешивает все узлы пройденного пути напрямую к корню
- Какая амортизированная стоимость у Union-find со сжатием пути и рангами? → O(α(n)), обратная функция Аккермана
- Что даёт сжатие пути без объединения по рангу? → O(log n) амортизированно, не O(α(n))
```
