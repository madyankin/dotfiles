# Interactive figures

Everything is **precomputed at generation time**. The widgets derive nothing themselves: every
option, analysis, gloss and explanation sits ready in `DATA`. The HTML opens from `file://`,
offline, with no network.

Choose **1–4 figures** that this material genuinely needs; in `text` and `grammatik` modes there
are at least two (the builder checks). `quiz` is always present. `glossen` is mandatory in `text`
mode. A superfluous figure is worse than no figure, and a decorative chart is worse than a
superfluous one. A figure replaces a paragraph: once you place a diagram, cut the prose beside it
to a single line.

## Catalogue

| `art` | What it does | When to use it |
|---|---|---|
| `satzklammer` | Highlights Vorfeld / finite verb / Mittelfeld / the second half of the bracket; a Hauptsatz ↔ Nebensatz toggle shows the verb moving to the end | compound predicates, modals, Perfekt, subordinate clauses |
| `kasus` | Click a noun phrase → case, gender, number, the cell in the article table, and a "why this case" line | case load, Wechselpräpositionen, verb government |
| `wortstellung` | A set of variants of one sentence, each marked ✅/❌ with the reason | Vorfeld, TeKaMoLo, position of `nicht`, inversion |
| `konjugator` | Tense/mood chips → the sentence is rewritten in full | tenses, Konjunktiv II, Passiv |
| `trennbar` | The prefix travels to the end and returns in Nebensatz / Infinitiv with `zu` | separable prefixes |
| `glossen` | Word → lemma, grammatical tag, Russian gloss; a global "hide all glosses" toggle for the second pass | always in `text` |
| `wortfeld` | Word clusters by meaning; collocation and example expand on click | `vokabeln` |

### Diagrams and charts

When a construction can be **shown** rather than described, show it. Everything is drawn with
inline SVG and CSS, no libraries.

| `art` | What it draws | When to use it |
|---|---|---|
| `feldermodell` | Field diagram: Vorfeld / linke Klammer / Mittelfeld / rechte Klammer / Nachfeld as columns, sentences as rows — the columns line up and the bracket becomes visible | word order, comparing Haupt- and Nebensatz, verb position |
| `zeitstrahl` | A time axis marked "jetzt"; clicking a point shows the sentence in that tense | tenses, sequence of tenses, Plusquamperfekt vs Perfekt |
| `raum` | A box and an object: clicking a preposition moves the object to the right place | local prepositions, Wechselpräpositionen, `an/auf/über/unter` |
| `valenz` | The verb at the centre, arrows to its arguments with case and question word | verb government, Dativ- and Akkusativergänzung |
| `wortnetz` | Radial graph of a word: synonyms, antonyms, derivatives, collocations as edges | `vokabeln`, analysis of one key word |
| `wortbau` | Breaks a compound or derivative into parts, head highlighted, each part glossed | long nouns, prefixes, suffixes |
| `fehlerprofil` | Horizontal bars: how many errors per category, click for an example | `fehler` |

The quiz is not a figure — it lives in `DATA.quiz` and is always rendered.

### When no chart is needed

- A diagram that merely repeats what the prose already said is noise. A diagram must show what prose
  explains badly: geometry, alignment, distance, connection.
- Do not draw a `zeitstrahl` for a single tense, or a `wortnetz` for two words.
- `feldermodell` earns its place from two sentences up: the whole point is that the columns align.
- `fehlerprofil` from three categories up; with two bars there is nothing to compare.

## Overall `DATA` structure

```js
const DATA = {
  meta: {
    thema:  "Wechselpräpositionen: Wohin vs. Wo",
    niveau: "A2",              // A1 | A2 | B1 | B2 | C1
    modus:  "grammatik",       // text | grammatik | vokabeln | fehler
    quelle: "Menschen A2, S. 44 (фото)",
    datum:  "2026-09-13",
    slug:   "2026-09-13-wechselpraepositionen"   // localStorage key
  },
  zweck:     ["<paragraph>", "<paragraph>"],
  intuition: [{ art: "p", text: "..." },
              { art: "beispiel", de: "Ich gehe in die Stadt.", ru: "Иду в город (движение)." },
              { art: "tabelle", kopf: ["", "Wohin?", "Wo?"], zeilen: [["in", "+ Akk", "+ Dat"]] }],
  leitbeispiel: { de: "...", ru: "...", ziel: "<what to watch for>", grenze: "<where the hint stops working>" },
  merksatz:  ["Двигается → Akkusativ. Стоит → Dativ."],   // 1–3 lines, ≤12 words each
  stuetzen:  ["<line>", "<line with [[wikilink]]>"],
  analyse:   [{ de: "<fragment>", wort: "<literal>", frei: "<idiomatic>", warum: "<one paragraph>",
                anker: true, figure_id: "main-model",
                details: [{ titel: "<qualification>", text: "<collapsible depth>" }] }],
  figuren:   [ /* objects from the catalogue below */ ],
  fallen:    [{ falsch: "Ich gehe in der Stadt.", richtig: "Ich gehe in die Stadt.",
                warum: "Движение → Akkusativ." }],
  quiz:      [ /* exactly 5 */ ],
  karten:    [{ v: "<front>", r: "<back>" }]
}
```

`fallen` also accepts the simple form `{ text: "..." }` when the mistake is not a before/after pair.

Every figure shares a common set of fields: a safe unique `id`, `titel`, `aria` (a self-contained
textual description of what the diagram means), `hinweis` ("what to manipulate") and `beobachtung`
("what you should have noticed" — hidden until the first interaction). Each `id` occurs exactly once
as an `analyse[].figure_id`, which is what places the diagram next to the explanation it belongs to.

Every question has a `fokus`; at least one question carries the `figure_id` of an existing diagram.

## Figure shapes

### `satzklammer`

`rolle` is one of: `junktor`, `vorfeld`, `finit`, `mittelfeld`, `klammer`, `nachfeld`.

```js
{ art: "satzklammer",
  titel: "Куда уезжает глагол",
  hinweis: "Переключи Hauptsatz / Nebensatz и посмотри на позицию finites Verb.",
  beobachtung: "В Nebensatz finites Verb встаёт последним, за второй частью рамки.",
  saetze: [
    { label: "Hauptsatz", teile: [
        { t: "Gestern",  rolle: "vorfeld" },
        { t: "habe",     rolle: "finit" },
        { t: "ich meinen Chef", rolle: "mittelfeld" },
        { t: "angerufen", rolle: "klammer" } ] },
    { label: "Nebensatz", teile: [
        { t: "weil",     rolle: "junktor" },
        { t: "ich meinen Chef", rolle: "mittelfeld" },
        { t: "angerufen", rolle: "klammer" },
        { t: "habe",     rolle: "finit" } ] } ] }
```

### `kasus`

The definite-article table is built into the renderer — do not populate it, just point at the cell
via `kasus` + `genus`/`zahl`.

```js
{ art: "kasus",
  titel: "Почему тут Akkusativ",
  hinweis: "Кликай по подчёркнутым группам.",
  beobachtung: "Предлог один и тот же, падеж меняет смысл: движение или место.",
  satz: [
    { t: "Ich stelle die Lampe" },
    { t: "in die Ecke", np: true, kasus: "akk", genus: "f", zahl: "sg",
      warum: "`stellen` — движение, значит `in` требует Akkusativ." },
    { t: "." } ] }
```

`kasus`: `nom` | `akk` | `dat` | `gen`. `genus`: `m` | `f` | `n`. `zahl`: `sg` | `pl`
(for `pl`, gender is ignored).

### `wortstellung`

```js
{ art: "wortstellung",
  titel: "Что можно поставить в Vorfeld",
  hinweis: "Щёлкай по вариантам.",
  beobachtung: "Меняется акцент, но finites Verb всегда второе.",
  varianten: [
    { satz: "Morgen fahre ich nach Köln.", ok: true,  warum: "Обстоятельство в Vorfeld, глагол второй." },
    { satz: "Morgen ich fahre nach Köln.", ok: false, warum: "Два элемента перед глаголом — так нельзя." } ] }
```

### `konjugator`

```js
{ art: "konjugator",
  titel: "Одно предложение во всех временах",
  hinweis: "Переключай чипы.",
  beobachtung: "В Perfekt меняется только рамка, порядок слов тот же.",
  formen: [
    { label: "Präsens",      satz: "Ich rufe dich an.",             notiz: "" },
    { label: "Perfekt",      satz: "Ich habe dich angerufen.",      notiz: "`haben` + Partizip II в конце." },
    { label: "Konjunktiv II", satz: "Ich würde dich anrufen.",      notiz: "«позвонил бы»" } ] }
```

### `trennbar`

```js
{ art: "trennbar",
  titel: "Куда девается приставка",
  hinweis: "Переключай формы и следи за чипом `an`.",
  beobachtung: "Приставка возвращается к глаголу только в Nebensatz и в инфинитиве.",
  verb: "anrufen", praefix: "an",
  varianten: [
    { label: "Hauptsatz", teile: [{ t: "Ich rufe dich morgen" }, { t: "an", p: true }, { t: "." }] },
    { label: "Nebensatz", teile: [{ t: "…, weil ich dich morgen" }, { t: "an", p: true }, { t: "rufe." }] } ] }
```

`p: true` marks the segment holding the prefix — it is highlighted and animated on toggle.

### `glossen`

```js
{ art: "glossen",
  titel: "Текст с глоссами",
  hinweis: "Клик по слову — разбор. Тумблер сверху прячет все глоссы для второго прохода.",
  beobachtung: "",
  text: [
    { t: "Die" },
    { t: "Entscheidung", g: { lemma: "die Entscheidung, -en", tag: "Nom. Sg. f.", ru: "решение" } },
    { t: "fiel" , g: { lemma: "fallen (fiel, ist gefallen)", tag: "Prät. 3. Sg.", ru: "здесь: была принята" } },
    { t: "gestern." } ] }
```

Gloss density follows the level (see `explainer-spec.md`). A word with no `g` is simply not clickable.

### `wortfeld`

```js
{ art: "wortfeld",
  titel: "Bewerbung: поле слов",
  hinweis: "Разворачивай карточки.",
  beobachtung: "Половина слов ходит с фиксированными глаголами — учи связками.",
  cluster: [
    { name: "Документы", woerter: [
        { de: "die Bewerbung, -en", ru: "заявка на работу",
          kollokation: "eine Bewerbung schreiben / einreichen",
          beispiel: "Ich habe meine Bewerbung gestern eingereicht." } ] } ] }
```

## Quiz

Exactly 5 objects. Types: `wahl` (2), `eingabe` (2), `ordnen` (1).

```js
quiz: [
  { typ: "wahl", frage: "Почему `in die Stadt`, а не `in der Stadt`?",
    optionen: [
      { t: "Движение к цели → Akkusativ", ok: true,  warum: "`gehen` задаёт направление." },
      { t: "`Stadt` женского рода",       ok: false, warum: "Род на выбор падежа тут не влияет." },
      { t: "`in` всегда с Akkusativ",     ok: false, warum: "`in` — Wechselpräposition, бывает и с Dativ." } ] },

  { typ: "eingabe", frage: "Вставь артикль: Ich warte auf ___ Bus.",
    hinweis: "`warten auf` + ?", antworten: ["den"],
    warum: "`warten auf` требует Akkusativ, `der Bus` → `den Bus`." },

  { typ: "ordnen", frage: "Собери Nebensatz.",
    teile: ["weil", "ich", "dich", "angerufen", "habe"],
    loesung: ["weil", "ich", "dich", "angerufen", "habe"],
    warum: "В Nebensatz finites Verb (`habe`) уходит в самый конец." }
]
```

Free-input normalisation is handled by the renderer: trim, case, `ä≡ae`, `ö≡oe`, `ü≡ue`, `ß≡ss`.
List every other acceptable answer explicitly in `antworten`.

### `feldermodell`

For an empty field use `''` and the renderer shows a dash. It only becomes meaningful from two rows
up: the columns align, and you can see the same content shifting between fields.

```js
{ art: "feldermodell",
  titel: "Одно предложение в двух режимах",
  hinweis: "Кликай по строкам.",
  beobachtung: "Mittelfeld не изменился — переехала только рамка.",
  saetze: [
    { label: "Hauptsatz", vorfeld: "Gestern", lk: "habe",
      mittelfeld: "ich meinen Chef", rk: "angerufen", nachfeld: "" },
    { label: "Nebensatz", vorfeld: "", lk: "weil",
      mittelfeld: "ich meinen Chef", rk: "angerufen habe", nachfeld: "" } ] }
```

### `zeitstrahl`

`pos` is the position on the axis, 0…100; `jetzt` is where the "now" dashed line sits.

```js
{ art: "zeitstrahl",
  titel: "Где какое время стоит",
  hinweis: "Кликай по точкам.",
  beobachtung: "Perfekt и Präteritum стоят в одной точке — разница не во времени, а в регистре.",
  jetzt: 60,
  punkte: [
    { label: "Plusquamperfekt", pos: 12, satz: "Ich hatte gegessen.", notiz: "до другого прошлого" },
    { label: "Perfekt",         pos: 38, satz: "Ich habe gegessen.",  notiz: "разговорное прошлое" },
    { label: "Futur I",         pos: 85, satz: "Ich werde essen.",    notiz: "" } ] }
```

### `raum`

`x`/`y` are percentages of the drawing area. The box occupies roughly `x` 34…66, `y` 37…77, so
"inside" ≈ `{x:50, y:57}`, "on top" ≈ `{x:50, y:30}`, "beside" ≈ `{x:78, y:57}`.

```js
{ art: "raum",
  titel: "Девять предлогов на одной картинке",
  hinweis: "Жми предлог — мяч переедет.",
  beobachtung: "Предлог задаёт геометрию, падеж — движение это или положение.",
  objekt: "der Ball", bezug: "die Kiste",
  praepositionen: [
    { p: "in",    x: 50, y: 57, kasus: "dat", satz: "Der Ball ist in der Kiste." },
    { p: "auf",   x: 50, y: 30, kasus: "dat", satz: "Der Ball ist auf der Kiste." },
    { p: "neben", x: 78, y: 57, kasus: "dat", satz: "Der Ball liegt neben der Kiste." } ] }
```

### `valenz`

```js
{ art: "valenz",
  titel: "Что требует helfen",
  hinweis: "Кликай по аргументам.",
  beobachtung: "У helfen дополнение в Dativ: это видно по dem Freund. Здесь русское и немецкое управление совпадают.",
  verb: "helfen", satz: "Ich helfe dem Freund.",
  argumente: [
    { rolle: "wer?", kasus: "nom", beispiel: "ich" },
    { rolle: "wem?", kasus: "dat", beispiel: "dem Freund", notiz: "не Akkusativ — частая ошибка." } ] }
```

### `wortnetz`

Nodes are laid out on an ellipse automatically; array order is the order around the circle.
Sensible between 3 and 8 nodes.

```js
{ art: "wortnetz",
  titel: "Arbeit и соседи",
  hinweis: "Кликай по узлам.",
  beobachtung: "Половина сетки — производные от одного корня, их не надо учить по отдельности.",
  zentrum: "die Arbeit",
  knoten: [
    { w: "der Job",      rel: "Synonym",   notiz: "разговорное" },
    { w: "arbeitslos",   rel: "Ableitung", beispiel: "Er ist seit einem Jahr arbeitslos." },
    { w: "die Freizeit", rel: "Gegenteil" } ] }
```

### `wortbau`

`fuge: true` marks a linking element (`-s-`, `-n-`), drawn small and grey.
`kopf` is the component that determines gender and core meaning; it is highlighted.

```js
{ art: "wortbau",
  titel: "Разбираем длинное слово",
  hinweis: "Кликай по частям.",
  beobachtung: "Род всего слова задаёт последний компонент, а не первый.",
  wort: "die Geschwindigkeitsbegrenzung",
  kopf: "Begrenzung",
  notiz: "читается справа налево: ограничение — чего? — скорости",
  teile: [
    { t: "Geschwindigkeit", artikel: "die", ru: "скорость" },
    { t: "s", fuge: true },
    { t: "Begrenzung", artikel: "die", ru: "ограничение" } ] }
```

### `fehlerprofil`

Bars are scaled to the maximum. Only for `fehler` mode, and only with at least three categories —
with fewer it is not a profile, just two numbers.

```js
{ art: "fehlerprofil",
  titel: "Куда утекают ошибки",
  hinweis: "Кликай по строкам.",
  beobachtung: "Две трети ошибок — один и тот же падеж после предлога. Учить надо не всё подряд.",
  kategorien: [
    { name: "Kasus nach Präposition",    n: 4, beispiel: "in der Stadt → in die Stadt" },
    { name: "Wortstellung im Nebensatz", n: 2, beispiel: "weil ich habe angerufen → weil ich angerufen habe" },
    { name: "Artikelgenus",              n: 1, beispiel: "das Termin → der Termin" } ] }
```

## Additional DATA fields for the builder

```json
{
  "meta": {
    "pages": ["19", "21"],
    "requested_pages": ["19", "21"],
    "page_map": [{"pdf_page": 4, "printed_pages": ["18", "19"]}]
  },
  "reference": [{"titel": "Формы глаголов", "text": "Примечание к таблице",
    "kopf": ["Infinitiv", "Perfekt"], "zeilen": [["gehen", "ist gegangen"]]}],
  "solutions": [{"titel": "Упражнение 3", "text": "Ответы с объяснениями"}]
}
```

These are additional fields, not a complete DATA. Pages are printed pages; `pdf_page` starts at 1.
`requested_pages` is what the user asked for, `pages` is what was actually analysed. The builder
checks that they agree, but substantive completeness is the author's job, against the pages
themselves. `analyse` takes optional `titel`, `herkunft` (`zitat`/`loesung`/`beispiel`) and `quelle`.
`ordnen` keeps its primary `loesung`; add `loesungen` as an array of every accepted sequence,
including the primary one. For example:
`[["Ich", "komme", "morgen"], ["Morgen", "komme", "ich"]]`.

## What the visualisations are for

Pick at least one explanatory diagram per HTML whenever the material contains a suitable relation:
government → `valenz`; tenses → `zeitstrahl`; word order → `feldermodell`; word formation →
`wortbau`; semantic relations → `wortnetz`. Colour is never the sole carrier of meaning: add labels
and a prose explanation for the note and for print. Do not invent numeric error frequencies just to
justify a `fehlerprofil`. Two coordinated views of one construction are worth more than several
unrelated illustrations.

On the time axis, do not separate Perfekt and Präteritum as "long ago / recently"; anchor
Plusquamperfekt to another past event. For Wechselpräpositionen, distinguish direction or change of
spatial relation from location: movement *within* a place also takes Dativ.
