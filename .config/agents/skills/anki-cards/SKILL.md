---
name: anki-cards
description: Create Anki flashcards and add them to the user's collection via the Anki MCP server (AnkiConnect fallback). Use when the user asks to make Anki cards, flashcards, spaced-repetition cards, or to "ankify" a topic, conversation, article, or code concept.
---

# Anki Cards

Turn content (conversation, docs, code, a topic) into well-formed Anki cards and add them to the user's collection.

## Setup

The `anki` MCP server (anki-mcp, https://ankimcp.ai) runs at `http://127.0.0.1:3141/`. Register it with whichever agent you use; in Claude Code its tools are prefixed `mcp__anki__` and load via `ToolSearch("anki")`.

Key tools: `list_decks`, `model_names`, `model_field_names`, `add_note`, `add_notes` (batch, one deck+model), `find_notes` (Anki query syntax), `update_note_fields`, `create_deck`, `sync`. GUI tools (`gui_*`) only when the user explicitly asks to open Anki windows.

## Workflow

1. **Pick the deck.** `list_decks` first. If the user named a deck, use it (`create_deck` if missing — supports `Parent::Child`). Otherwise pick the best-matching existing deck and say which one you chose. Never invent a new deck silently.
2. **Pick the model.** `model_names`, then `model_field_names` to get exact field names. Prefer Basic (Front/Back) or Cloze.
3. **Draft the cards** following the quality rules below.
4. **Show the drafts** to the user in the reply (front/back or cloze text, deck, tags).
5. **Add with `add_notes`** (batch), then report how many were created and any duplicates that were skipped. Suggest `sync` when done.

If the MCP tools are missing, use the AnkiConnect fallback below.

## Card quality rules

- **One fact per card.** Split compound facts. 5 small cards beat 1 big card.
- **Front is a question** the user must actively answer. No yes/no questions — rephrase as "what/why/how/when".
- **Minimum information principle:** back contains the shortest correct answer, not a paragraph. Extra context goes in a separate "Extra" field or a follow-up card.
- **Self-contained:** the front must make sense months later without conversation context. "What does `useMemo` cache?" not "What does the hook we discussed cache?"
- **Cloze** (`{{c1::...}}`) for lists, sequences, and fill-in-the-blank facts. Use separate cloze indices (`c1`, `c2`, ...) so each blank becomes its own card. Requires the Cloze note type.
- **Basic** note type for plain Q→A. Prefer Basic unless cloze clearly fits better.
- Fields accept HTML: `<br>` for line breaks, `<code>`/`<pre>` for code. Escape `<` and `>` in code samples.
- **Tags:** kebab-case topic tags plus a source tag (e.g. `ruby`, `concurrency`, `src-claude`).

### Example

Bad: front "Explain Ruby's GVL" / back: three paragraphs.

Good:
- Front: "What does Ruby's GVL prevent?" / Back: "Two threads executing Ruby code in parallel in one process."
- Front: "Which operations release the GVL?" / Back: "Blocking I/O and some C extensions."

## AnkiConnect fallback (no MCP tools)

Anki desktop must be running with the AnkiConnect add-on (port 8765).

```bash
# list decks
curl -s localhost:8765 -d '{"action":"deckNames","version":6}'

# add notes (batch)
curl -s localhost:8765 -d '{
  "action": "addNotes", "version": 6,
  "params": { "notes": [{
    "deckName": "Programming",
    "modelName": "Basic",
    "fields": { "Front": "What does Ruby'"'"'s GVL prevent?",
                "Back": "Two threads executing Ruby code in parallel in one process." },
    "tags": ["ruby", "concurrency"],
    "options": { "allowDuplicate": false, "duplicateScope": "deck" }
  }]}
}'
```

`addNotes` returns an array of note IDs; `null` entries are duplicates or failures. For cloze notes use `"modelName": "Cloze"` with fields `Text` and `Back Extra`.

## Errors

- Connection refused on 3141 or MCP tool errors about the Anki API: Anki desktop is not running or the anki-mcp add-on/server is down — tell the user to open Anki, don't retry blindly.
- Unknown model name: list models first and use one that exists; field names must match the model exactly.
