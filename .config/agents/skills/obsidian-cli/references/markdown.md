# Obsidian Markdown Conventions

Use these standards when creating or editing Obsidian notes.

## Linking
- **Internal Links**: Use Wikilinks `[[Note Name]]` instead of standard Markdown links `[Note Name](note-name.md)`.
- **Embeds**: Use `![[Note Name]]` to embed another note.
- **Header Links**: Use `[[Note Name#Header Name]]` to link to a specific header.
- **Block Links**: Use `[[Note Name#^block-id]]` for specific block references.

## Properties (YAML Frontmatter)
Always include properties at the top of a note between `---` markers.
Common fields:
- `tags`: List of tags (`#status/todo`, `#project/name`).
- `created`: Date or timestamp.
- `status`: Lifecycle state (e.g., `active`, `archived`).
- `aliases`: Alternative names for the note.

Example:
```markdown
---
tags:
  - project/active
  - status/todo
created: 2026-03-07
status: active
aliases:
  - CLI Skill
---
```

## Callouts
Use callouts for highlighting information.
- `> [!INFO]`: Standard informational block.
- `> [!TODO]`: Task or action item.
- `> [!WARNING]`: Critical warning.
- `> [!QUOTE]`: Citation or quoted text.

## Task Management
- `- [ ] Task Name`: Standard task checkbox.
- `- [/] Task Name`: Task in progress (supported by some plugins).
- `- [x] Task Name`: Completed task.
- `- [!] Task Name`: High-priority task.

## Tagging
- Use hierarchical tags with slashes (`#category/sub-category`).
- Prefer tags in the properties section for better organization.
