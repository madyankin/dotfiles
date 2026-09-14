#!/usr/bin/env bash
#
# Put `dot` on PATH.
#
# The link target is RELATIVE, following the rule scripts/agents.sh documents:
# an absolute path here would bake this username into a public repo.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
LINK="$BIN_DIR/dot"
TARGET="../../.config/yadm/bin/dot"

mkdir -p "$BIN_DIR"

# `ln -sfn` into an existing DIRECTORY creates the link inside it instead of
# replacing it — the footgun agents.sh warns about. Remove first.
if [[ -L "$LINK" || -e "$LINK" ]]; then
  rm -f "$LINK"
fi
ln -s "$TARGET" "$LINK"

echo "→ linked $LINK -> $TARGET"
if [[ "$(command -v dot 2>/dev/null)" == "$LINK" ]]; then
  echo "  ✓ dot resolves to the link"
else
  echo "  ! dot resolves to $(command -v dot 2>/dev/null || echo 'nothing') — open a new shell"
fi
