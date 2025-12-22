#!/usr/bin/env bash
set -euo pipefail

source $HOME/.zshenv
cd $HOME

# Save editor extensions before commit
$HOME/.config/yadm/scripts/editors.sh save > /dev/null 2>&1 || true

yadm add -u

yadm commit -m "Commited via cron $(date -u)" > /dev/null 2>&1
yadm pull --rebase > /dev/null 2>&1

yadm push > /dev/null 2>&1

# Install any new extensions after sync
$HOME/.config/yadm/scripts/editors.sh install > /dev/null 2>&1 || true
