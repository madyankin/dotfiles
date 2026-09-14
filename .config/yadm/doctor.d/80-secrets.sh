#!/usr/bin/env bash
# dot:check=no tracked file matches the pre-commit credential patterns
set -uo pipefail
rc=0

# The pre_commit hook guards NEW commits. This catches anything that landed
# before the hook existed. Report the file and the pattern, never the value.
#
# Patterns require a PLAUSIBLE TOKEN LENGTH, not just the prefix. The hook's
# shorter patterns are fine against a diff of added lines; run over every
# tracked file they match ordinary prose ("task-local", "risk-averse") and
# produce nothing but noise.
#
# One grep over one file list. The first version re-ran `yadm ls-files` inside
# a loop for each of eight patterns — 2000+ greps, and it took minutes.
PATTERNS_FILE="$(mktemp)"
trap 'rm -f "$PATTERNS_FILE"' EXIT
cat > "$PATTERNS_FILE" <<'PATS'
sk-[A-Za-z0-9_-]{20,}
ghp_[A-Za-z0-9]{36,}
gho_[A-Za-z0-9]{36,}
github_pat_[A-Za-z0-9_]{22,}
AKIA[0-9A-Z]{16}
xox[baprs]-[A-Za-z0-9-]{10,}
BEGIN (RSA|OPENSSH|DSA|EC|PGP) PRIVATE KEY
_authToken=[A-Za-z0-9]
PATS

FILES="$(mktemp)"
trap 'rm -f "$PATTERNS_FILE" "$FILES"' EXIT
# The hook file IS the pattern list, and these checks quote patterns too.
( cd "$HOME" && yadm ls-files 2>/dev/null ) \
  | grep -v '^\.config/yadm/hooks/pre_commit$' \
  | grep -v '^\.config/yadm/doctor\.d/' \
  > "$FILES"

hits=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  [[ -f "$HOME/$f" ]] || continue
  if LC_ALL=C grep -qaEf "$PATTERNS_FILE" "$HOME/$f" 2>/dev/null; then
    pat="$(LC_ALL=C grep -oaEf "$PATTERNS_FILE" "$HOME/$f" 2>/dev/null | head -1 | cut -c1-8)"
    err "tracked file matches a credential-shaped string (prefix '${pat}…'): $f"
    hits=$((hits+1)); rc=1
  fi
done < "$FILES"

if [[ $hits -eq 0 ]]; then
  ok "no tracked file matches a credential pattern ($(wc -l < "$FILES" | tr -d ' ') files scanned)"
fi
exit $rc
