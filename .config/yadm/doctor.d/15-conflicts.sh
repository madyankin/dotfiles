#!/usr/bin/env bash
# dot:check=no tracked file contains merge conflict markers
set -uo pipefail
rc=0

# The sync pulls with --rebase --autostash unattended, so a conflict can leave
# <<<<<<< lines in a machine-written file. Once committed they look like data:
# workflows.txt carried them into a commit and nobody noticed until the list
# came out wrong on the other machine.
hits=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  [[ -f "$HOME/$f" ]] || continue
  case "$f" in .config/yadm/doctor.d/*) continue ;; esac
  if LC_ALL=C grep -qaE '^(<<<<<<< |>>>>>>> |\|\|\|\|\|\|\| )' "$HOME/$f" 2>/dev/null; then
    err "conflict markers in tracked file: $f"
    hits=$((hits+1)); rc=1
  fi
done <<<"$(cd "$HOME" && yadm ls-files 2>/dev/null)"

[[ $hits -eq 0 ]] && ok "no tracked file contains conflict markers"

# A leftover autostash means a previous unattended pull did not finish cleanly.
n="$(cd "$HOME" && yadm stash list 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$n" != "0" ]]; then
  warn "$n stash entry/entries left over (autostash from an interrupted sync)"
  note "inspect with: yadm stash show --stat stash@{0}"
else
  ok "no leftover stashes"
fi
exit $rc
