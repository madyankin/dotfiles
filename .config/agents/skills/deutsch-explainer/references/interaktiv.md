# Интерактивные фигуры

Всё **предвычислено на этапе генерации**. Виджеты ничего не выводят сами: все варианты, разборы,
глоссы и объяснения лежат готовыми в `DATA`. HTML открывается из `file://`, офлайн, без сети.

Выбирай **1–3 фигуры**, которые этому материалу реально нужны. `quiz` — всегда. `glossen` —
обязательно в режиме `text`. Лишняя фигура хуже, чем её отсутствие.

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

Квиз — не фигура, он лежит в `DATA.quiz` и рендерится всегда.

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
