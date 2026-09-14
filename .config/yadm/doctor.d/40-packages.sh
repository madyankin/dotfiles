#!/usr/bin/env bash
# dot:check=Brewfile manifests match reality, in both directions
set -uo pipefail
rc=0
PKG_DIR="$DOT_ROOT/packages"

have brew || { warn "brew not installed"; exit 0; }

# Snapshot everything ONCE, up front, with stdin closed.
#
# The first version of this check ran `brew list` inside a `while read` loop
# fed by a here-string. Commands in such a loop inherit the loop's stdin and
# can eat the lines it has not read yet, which produced confident nonsense —
# packages that are plainly installed reported as missing. Precomputing also
# turns ~40 brew invocations into two.
INSTALLED_FORMULAE="$(brew list --formula 2>/dev/null </dev/null)"
LEAVES="$(brew leaves 2>/dev/null </dev/null)"
MANIFEST_FORMULAE="$(grep -h '^brew "' "$PKG_DIR"/Brewfile.* 2>/dev/null \
                     | sed 's/^brew "\([^"]*\)".*/\1/' | sort -u)"

in_list() { grep -qx -- "$1" <<<"$2"; }

# `brew leaves` prints TAP-QUALIFIED names (remerge/agent-sandbox/agent-sandbox)
# while `brew list --formula` and the manifests use the bare name. Compare the
# last path segment or a tapped formula reports as both missing and unmanaged.
bare() { printf '%s' "${1##*/}"; }

# --- manifest names must be CANONICAL ---------------------------------------
# `brew "delta"` and `brew "mc"` are aliases. install.sh compares against
# `brew list --formula`, which prints canonical names, so an alias reports
# "not installed" forever and the group never reaches <All> installed.
bad=0
for name in $MANIFEST_FORMULAE; do
  if ! in_list "$name" "$INSTALLED_FORMULAE"; then
    full="$(brew info --json=v2 --formula "$name" 2>/dev/null </dev/null \
            | "${DOT_JQ:-jq}" -r '.formulae[0].full_name // empty' 2>/dev/null)"
    if [[ -n "$full" && "$full" != "$name" ]]; then
      err "manifest uses the alias '$name' — canonical name is '$full'"
      bad=$((bad+1)); rc=1
    fi
  fi
done
[[ $bad -eq 0 ]] && ok "all manifest formula names are canonical"

# --- manifest -> installed ---------------------------------------------------
missing=""
for name in $MANIFEST_FORMULAE; do
  in_list "$(bare "$name")" "$INSTALLED_FORMULAE" || missing="${missing:+$missing }$name"
done
if [[ -n "$missing" ]]; then
  warn "manifested but not installed: $missing"
else
  ok "every manifested formula is installed ($(wc -w <<<"$MANIFEST_FORMULAE" | tr -d ' ') names)"
fi

# --- installed -> manifest ---------------------------------------------------
# `brew leaves` (top-level, ~46) not `brew list --formula` (~179, mostly
# transitive dependencies that have no business in a manifest).
# Deliberate exclusions, so this warning does not become permanent noise.
ALLOW_FILE="$DOT_ROOT/doctor.d/packages.allow"
allowed="$(sed 's/#.*//; s/[[:space:]]*$//' "$ALLOW_FILE" 2>/dev/null | grep -v '^$')"
MANIFEST_BARE="$(for n in $MANIFEST_FORMULAE; do bare "$n"; echo; done)"

unmanaged=""
n=0
for name in $LEAVES; do
  b="$(bare "$name")"
  in_list "$b" "$MANIFEST_BARE" && continue
  in_list "$b" "$allowed" && continue
  unmanaged="${unmanaged:+$unmanaged }$b"; n=$((n+1))
done
if [[ $n -gt 0 ]]; then
  warn "$n top-level formula(e) installed but in no manifest — a rebuilt machine would not get them:"
  printf '%s\n' "$unmanaged" | fold -s -w 88 | sed 's/^/      /'
else
  ok "every top-level formula is manifested"
fi

exit $rc
