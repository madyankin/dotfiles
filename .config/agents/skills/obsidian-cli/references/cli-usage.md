# Obsidian CLI Usage Guide

The `obsidian` command interacts with a running Obsidian instance.

## Core Commands

### Search
Search for content across the entire vault.
- `obsidian search "query"`: Standard text search.
- `obsidian search --json "query"`: Returns structured JSON results (preferred for programmatic parsing).
- `obsidian search --tag "#status/todo"`: Find notes with specific tags.

### Notes
- `obsidian open "Note Name"`: Open a specific note in the GUI.
- `obsidian read "Note Name"`: Output the content of a note to stdout.
- `obsidian create "Note Name" --content "..."`: Create a new note.
- `obsidian append "Note Name" --content "..."`: Append content to an existing note.

### Daily Notes
- `obsidian daily`: Open or retrieve the today's daily note.
- `obsidian daily --date "2023-10-27"`: Access a specific daily note.
- `obsidian daily:append --content "..."`: Add a task or entry to today's note.

### Metadata & Graph
- `obsidian backlinks "Note Name"`: List all notes that link to the specified note.
- `obsidian properties "Note Name"`: Output YAML frontmatter as JSON.
- `obsidian tags`: List all tags in the vault.

### Advanced
- `obsidian eval --code "app.vault.getMarkdownFiles().length"`: Execute arbitrary JavaScript in the Obsidian environment.
- `obsidian vault list`: List all known vaults.
- `obsidian vault set "My Vault"`: Set the active vault for the session.

## Error Handling
- If `obsidian` command is not found, advise the user to install the Obsidian CLI (`npm install -g obsidian-cli`).
- If Obsidian is not running, the CLI will fail. Check for the running process before executing commands.
