#!/bin/bash

# Check if obsidian command is available
if ! command -v obsidian &> /dev/null; then
    echo "Error: 'obsidian' command not found. Please install the Obsidian CLI (e.g., 'npm install -g obsidian-cli')."
    exit 1
fi

# Check if Obsidian app is running (macOS)
if ! pgrep -x "Obsidian" &> /dev/null; then
    echo "Warning: Obsidian app is not running. The CLI requires a running instance."
    # We exit with 0 because the command is found, but the app is not running (user might need to start it)
    exit 0
fi

echo "Success: Obsidian CLI is available and Obsidian app is running."
exit 0
