# Интерактивные фигуры

Всё **предвычислено на этапе генерации**. Виджеты ничего не выводят сами: все варианты, разборы,
глоссы и объяснения лежат готовыми в `DATA`. HTML открывается из `file://`, офлайн, без сети.

Выбирай **1–4 фигуры**, которые этому материалу реально нужны. `quiz` — всегда. `glossen` —
обязательно в режиме `text`. Лишняя фигура хуже, чем её отсутствие, а декоративный график —
хуже лишней фигуры.

## Каталог

| `art` | Что делает | Когда брать |
|---|---|---|
| `satzklammer` | Подсвечивает Vorfeld / finites Verb / Mittelfeld / вторую часть рамки; тумблер Hauptsatz ↔ Nebensatz показывает, как глагол уезжает в конец | составное сказуемое, модальные, Perfekt, придаточные |
| `kasus` | Клик по именной группе → падеж, род, число, клетка в таблице артиклей и строка «почему именно этот падеж» | падежная нагрузка, Wechselpräpositionen, управление глаголов |
| `wortstellung` | Набор вариантов одного предложения, каждый помечен ✅/❌ с причиной | Vorfeld, TeKaMoLo, позиция `nicht`, инверсия |
| `konjugator` | Чипы времени/наклонения → предложение переписывается целиком | времена, Konjunktiv II, Passiv |
| `trennbar` | Приставка отъезжает в конец и возвращается в Nebensatz / Infinitiv с `zu` | отделяемые приставки |
| `glossen` | Слово → лемма, грамматический тег, русский глосс; общий тумблер «скрыть все глоссы» для второго прохода | всегда в `text` |
| `wortfeld` | Кластеры слов по смыслу, коллокация и пример разворачиваются по клику | `vokabeln` |

### Схемы и графики

Когда конструкцию можно **показать**, а не описать — показывай. Всё рисуется инлайновым SVG и CSS,
без библиотек.

| `art` | Что рисует | Когда брать |
|---|---|---|
| `feldermodell` | Полевая схема: Vorfeld / linke Klammer / Mittelfeld / rechte Klammer / Nachfeld колонками, предложения строками — колонки выровнены, и рамка видна глазом | порядок слов, сравнение Haupt- и Nebensatz, позиция глагола |
| `zeitstrahl` | Ось времени с отметкой «jetzt»; клик по точке показывает предложение в этом времени | времена, согласование времён, Plusquamperfekt vs Perfekt |
| `raum` | Коробка и объект: клик по предлогу перемещает объект в нужное место | локальные предлоги, Wechselpräpositionen, `an/auf/über/unter` |
| `valenz` | Глагол в центре, стрелки к его аргументам с падежом и вопросом | управление глаголов, Dativ- и Akkusativergänzung |
| `wortnetz` | Радиальный граф слова: синонимы, антонимы, производные, коллокации рёбрами | `vokabeln`, разбор одного ключевого слова |
| `wortbau` | Разбор композита/производного на части, голова подсвечена, у каждой части глосс | длинные существительные, приставки, суффиксы |
| `fehlerprofil` | Горизонтальные столбики: сколько ошибок в каждой категории, клик — пример | `fehler` |

Квиз — не фигура, он лежит в `DATA.quiz` и рендерится всегда.

### Когда график не нужен

- Диаграмма, которая просто повторяет уже сказанное словами, — мусор. Схема обязана показывать то,
  что текстом объясняется плохо: геометрию, выравнивание, расстояние, связь.
- Не рисуй `zeitstrahl` ради одного времени и `wortnetz` ради двух слов.
- `feldermodell` имеет смысл от двух предложений: вся суть — в том, что колонки выровнены.
- `fehlerprofil` — от трёх категорий; на двух столбиках сравнивать нечего.

## Общая структура `DATA`

```js
const DATA = {
  meta: {
    thema:  "Wechselpräpositionen: Wohin vs. Wo",
    niveau: "A2",              // A1 | A2 | B1 | B2 | C1
    modus:  "grammatik",       // text | grammatik | vokabeln | fehler
    quelle: "Menschen A2, S. 44 (фото)",
    datum:  "2026-09-13",
    slug:   "2026-09-13-wechselpraepositionen"   // ключ для localStorage
  },
  zweck:     ["абзац", "абзац"],
  intuition: [{ art: "p", text: "..." },
              { art: "beispiel", de: "Ich gehe in die Stadt.", ru: "Иду в город (движение)." },
              { art: "tabelle", kopf: ["", "Wohin?", "Wo?"], zeilen: [["in", "+ Akk", "+ Dat"]] }],
  stuetzen:  ["строка", "строка с [[wikilink]]"],
  analyse:   [{ de: "фрагмент", wort: "дословно", frei: "нормальный перевод", warum: "один абзац" }],
  figuren:   [ /* объекты из каталога ниже */ ],
  fallen:    [{ falsch: "Ich gehe in der Stadt.", richtig: "Ich gehe in die Stadt.",
                warum: "Движение → Akkusativ." }],
  quiz:      [ /* ровно 5 */ ],
  karten:    [{ v: "лицевая", r: "оборот" }]
}
```

`fallen` допускает и простую форму `{ text: "..." }`, когда ошибка не про пару «было/стало».
У каждой фигуры есть общие поля: `titel`, `hinweis` («что покрутить»), `beobachtung`
(«что ты должен был заметить» — скрыто до первого взаимодействия).

## Формы фигур

### `satzklammer`

`rolle` одно из: `junktor`, `vorfeld`, `finit`, `mittelfeld`, `klammer`, `nachfeld`.

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

Таблица определённых артиклей зашита в рендер — её заполнять не надо, только указать клетку
через `kasus` + `genus`/`zahl`.

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
(для `pl` род игнорируется).

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

`p: true` помечает сегмент с приставкой — он подсвечивается и анимируется при переключении.

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

Плотность глосс — по уровню (см. `explainer-spec.md`). Слово без `g` просто не кликается.

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

## Квиз

Ровно 5 объектов. Типы: `wahl` (2 шт.), `eingabe` (2 шт.), `ordnen` (1 шт.).

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

Нормализация свободного ввода делается рендером: trim, регистр, `ä≡ae`, `ö≡oe`, `ü≡ue`, `ß≡ss`.
Всё остальное допустимое перечисляй явно в `antworten`.

### `feldermodell`

Пустое поле — ставь `''`, рендер покажет прочерк. Смысл появляется от двух строк и выше:
колонки выровнены, и видно, как одно и то же содержание перекладывается между полями.

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

`pos` — позиция на оси 0…100, `jetzt` — где стоит пунктир «сейчас».

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

`x`/`y` — проценты от поля рисунка. Коробка занимает примерно `x` 34…66, `y` 37…77,
так что «внутри» ≈ `{x:50, y:57}`, «сверху» ≈ `{x:50, y:30}`, «рядом» ≈ `{x:78, y:57}`.

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
  beobachtung: "В русском «помогать кому» — дательный, и в немецком тоже. Совпало, редкий случай.",
  verb: "helfen", satz: "Ich helfe dem Freund.",
  argumente: [
    { rolle: "wer?", kasus: "nom", beispiel: "ich" },
    { rolle: "wem?", kasus: "dat", beispiel: "dem Freund", notiz: "не Akkusativ — частая ошибка." } ] }
```

### `wortnetz`

Узлы раскладываются по эллипсу автоматически, порядок в массиве = порядок по кругу.
Осмысленно от 3 до 8 узлов.

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

`fuge: true` — соединительный элемент (`-s-`, `-n-`), рисуется мелким и серым.
`kopf` — компонент, задающий род и основное значение; подсвечивается.

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

Столбики масштабируются к максимуму. Только для режима `fehler`, и только когда категорий
хотя бы три — иначе это не профиль, а два числа.

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
