#!/usr/bin/env bash
# dot:check=palette vs what each app actually uses
set -uo pipefail
exec "$DOT_ROOT/scripts/theme.sh" doctor
