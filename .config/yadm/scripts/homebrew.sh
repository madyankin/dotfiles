#!/usr/bin/env bash
#
# Ensures Homebrew exists, then hands over to the install wizard.
#
# The package lists that used to live here are now manifests in
# .config/yadm/packages/Brewfile.* — one per group — so they can be read by the
# wizard, diffed against what is installed, and applied in both directions.
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

exec "$(dirname "${BASH_SOURCE[0]}")/install.sh" "$@"
