#!/usr/bin/env bash
#
# Install the tracked crontab. Replaces the whole user crontab, so anything
# not in .config/yadm/crontab is dropped.
set -euo pipefail

CRONTAB="$HOME/.config/yadm/crontab"

if [[ ! -f "$CRONTAB" ]]; then
  echo "  ✗ $CRONTAB not found" >&2
  exit 1
fi

crontab "$CRONTAB"
echo "→ Installed crontab:"
crontab -l | sed 's/^/  /'
