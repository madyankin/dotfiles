#!/usr/bin/env bash
#
# Alfred configuration sync.
#
# The preference bundle lives in ~/.config/yadm/alfred/ and Alfred's sync folder
# points at it, so settings, web searches, themes and Alfred Remote pages are
# version-controlled directly.
#
# Workflows are handled differently. Third-party workflows are code — 17MB of
# it, including dozens of third-party executables — so instead of vendoring them
# the list is recorded in workflows.txt and they are reinstalled from source.
# Workflows you wrote yourself (no `webaddress` in info.plist) ARE tracked, since
# nothing else can restore them.
#
# No workflow prefs.plist is ever tracked: that is where workflows keep their
# settings, and at least one keeps a plaintext API key there.

set -uo pipefail

ALFRED_DIR="$HOME/.config/yadm/alfred"
BUNDLE="$ALFRED_DIR/Alfred.alfredpreferences"
WORKFLOWS="$BUNDLE/workflows"
LIST="$ALFRED_DIR/workflows.txt"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

plist() {  # plist <key> <info.plist>
  /usr/libexec/PlistBuddy -c "Print :$1" "$2" 2>/dev/null
}

# A workflow with no webaddress was authored locally; it is tracked in git
# rather than reinstalled.
is_own() {  # is_own <workflow dir>
  [[ -z "$(plist webaddress "$1/info.plist")" ]]
}

require_bundle() {
  if [[ ! -d "$BUNDLE" ]]; then
    echo "  ✗ No bundle at $BUNDLE" >&2
    exit 1
  fi
}

# --- Record which third-party workflows are installed -------------------------

save_workflows() {
  require_bundle
  echo "→ Saving workflow list..."

  local tmp merged own=0 third=0
  tmp="$(mktemp)"; merged="$(mktemp)"
  : > "$tmp"

  for d in "$WORKFLOWS"/*/; do
    [[ -f "$d/info.plist" ]] || continue
    if is_own "$d"; then
      own=$((own+1))
      continue
    fi
    printf '%s\t%s\t%s\t%s\n' \
      "$(plist bundleid "$d/info.plist")" \
      "$(plist name "$d/info.plist")" \
      "$(plist version "$d/info.plist")" \
      "$(plist webaddress "$d/info.plist")" >> "$tmp"
    third=$((third+1))
  done

  # UNION with whatever is already recorded, never an overwrite.
  #
  # This used to be `> "$LIST"` from the local install set alone, which made
  # the file a per-machine inventory masquerading as shared state: each
  # machine's sync deleted the other's entries, and one did exactly that in
  # commit 360783f (-37 lines). The list means "workflows I want on any
  # machine", which is also what `install` needs it to mean.
  #
  # Removing one therefore needs workflows.ignore — see below.
  # Conflict markers are filtered out defensively: this file is written by a
  # script and merged by the unattended sync, so a rebase can leave <<<<<<<
  # lines in it — and once committed they look like data. That has happened.
  { grep -v '^#' "$LIST" 2>/dev/null \
      | grep -vE '^(<<<<<<<|=======|>>>>>>>|\|\|\|\|\|\|\|)' \
      | grep -v '^[[:space:]]*$'; cat "$tmp"; } \
    | awk -F'\t' 'NF >= 2' \
    | sort -t$'\t' -k1,1 -k3,3V \
    | awk -F'\t' '{ line[$1] = $0 } END { for (b in line) print line[b] }' \
    > "$merged"

  # Drop anything deliberately unwanted.
  local ignore="$ALFRED_DIR/workflows.ignore"
  if [[ -f "$ignore" ]]; then
    grep -v '^#' "$ignore" | grep -v '^[[:space:]]*$' > "$tmp.ig" 2>/dev/null || : > "$tmp.ig"
    if [[ -s "$tmp.ig" ]]; then
      grep -vF -f "$tmp.ig" "$merged" > "$tmp.keep" && mv "$tmp.keep" "$merged"
    fi
    rm -f "$tmp.ig"
  fi

  {
    echo "# Third-party Alfred workflows, reinstalled by \`alfred.sh install\`."
    echo "# Own workflows are tracked in git instead and are not listed here."
    echo "#"
    echo "# This is a UNION across machines, not this machine's inventory: an"
    echo "# entry is never dropped just because it is not installed here."
    echo "# To remove one for good, add its bundleid to workflows.ignore."
    echo "# bundleid<TAB>name<TAB>version<TAB>source"
    sort -t$'\t' -k2,2 "$merged"
  } > "$LIST"
  rm -f "$tmp" "$merged"

  local total; total="$(grep -vc '^#' "$LIST")"
  echo "  ✓ $third installed here, $total listed across all machines"
  echo "  ✓ $own own workflow(s) tracked in git directly"

  # An own workflow that git is not tracking would be lost on a rebuild.
  for d in "$WORKFLOWS"/*/; do
    [[ -f "$d/info.plist" ]] || continue
    is_own "$d" || continue
    if ! yadm ls-files --error-unmatch "$d/info.plist" >/dev/null 2>&1; then
      echo "  ! $(plist name "$d/info.plist") is your own workflow but is NOT tracked."
      echo "    Add a negation for $(basename "$d") to .gitignore."
    fi
  done
}

# --- Reinstall third-party workflows -----------------------------------------

installed_bundleids() {
  for d in "$WORKFLOWS"/*/; do
    [[ -f "$d/info.plist" ]] && plist bundleid "$d/info.plist"
  done
}

# GitHub-hosted workflows can be fetched outright; anything else we can only
# open in a browser, so say so rather than pretending it was installed.
install_one() {  # install_one <bundleid> <name> <source>
  local id="$1" name="$2" src="$3" repo url tmp dest got

  # A .alfredworkflow is a ZIP, and Alfred loads workflows from plain
  # directories under Alfred.alfredpreferences/workflows/. So unzip it into
  # place instead of handing the file to Alfred.
  #
  # `open "$tmp"` was never unattended: Alfred shows an import sheet that has
  # to be clicked per workflow, and opening several at once fails outright with
  # "Unable to import workflow — please close the sheet you are currently
  # editing". UI-scripting that sheet would need Accessibility permission and
  # careful serialisation for no benefit.
  #
  # Trade-off worth knowing: the import sheet strips hotkeys and snippet
  # triggers "for predictability", and lets you set the workflow's own
  # configuration. Unzipping keeps the author's defaults, hotkeys included.

  # An override wins over the manifest's source column, which comes from the
  # workflow's own `webaddress` plist key and is usually the author's homepage
  # rather than a repository.
  local override
  override="$(awk -F'\t' -v id="$id" '$1 == id { print $2; exit }' \
              "$ALFRED_DIR/workflows.sources" 2>/dev/null)"
  [[ -n "$override" ]] && src="$override"

  url="$(/usr/bin/python3 "$SCRIPTS_DIR/alfred-resolve-download.py" "$src" 2>/dev/null)"
  if [[ -z "$url" ]]; then
    echo "  ! $name — no .alfredworkflow found for '$src'; opening it instead"
    echo "    add '$id<TAB>owner/repo' to alfred/workflows.sources to fix this"
    open "$src"
    return 0
  fi

  tmp="$(mktemp -d)/wf.alfredworkflow"
  if ! curl -fsSL -o "$tmp" "$url"; then
    echo "  ✗ $name — download failed"
    rm -rf "${tmp%/*}"
    return 1
  fi

  dest="$WORKFLOWS/user.workflow.$(uuidgen)"
  mkdir -p "$dest"
  if ! unzip -qq -o "$tmp" -d "$dest" 2>/dev/null; then
    echo "  ✗ $name — not a readable zip"
    rm -rf "$dest" "${tmp%/*}"
    return 1
  fi
  rm -rf "${tmp%/*}"

  if [[ ! -f "$dest/info.plist" ]]; then
    echo "  ✗ $name — no info.plist in the archive"
    rm -rf "$dest"
    return 1
  fi

  # Verify we installed what the manifest asked for, so a renamed release or a
  # wrong URL cannot quietly install something else.
  got="$(plist bundleid "$dest/info.plist")"
  if [[ -n "$id" && -n "$got" && "$got" != "$id" ]]; then
    echo "  ✗ $name — archive is '$got', manifest says '$id'; not installing"
    rm -rf "$dest"
    return 1
  fi

  echo "  ✓ $name — unzipped to ${dest##*/}"
  ALFRED_NEEDS_RELAUNCH=1
  return 0
}

install_workflows() {
  require_bundle
  if [[ ! -f "$LIST" ]]; then
    echo "  ✗ No $LIST — run 'alfred.sh save' first" >&2
    exit 1
  fi
  echo "→ Installing missing workflows..."

  local present missing=0
  present="$(installed_bundleids)"

  while IFS=$'\t' read -r id name version src; do
    [[ -z "${id:-}" || "$id" == \#* ]] && continue
    grep -qx -- "$id" <<<"$present" && continue
    missing=$((missing+1))
    install_one "$id" "$name" "$src"
  done < "$LIST"

  if [[ $missing -eq 0 ]]; then
    echo "  ✓ all listed workflows already installed"
    return 0
  fi

  # Once, at the end — not per workflow. Alfred indexes the workflows folder at
  # launch, so a directory dropped in while it is running is not picked up
  # until it restarts.
  if [[ -n "${ALFRED_NEEDS_RELAUNCH:-}" ]]; then
    echo "→ Relaunching Alfred so it indexes the new workflows..."
    osascript -e 'quit app id "com.runningwithcrayons.Alfred"' >/dev/null 2>&1 || true
    sleep 2
    open -b com.runningwithcrayons.Alfred >/dev/null 2>&1 \
      && echo "  ✓ Alfred relaunched" \
      || echo "  ! could not relaunch Alfred — start it by hand"
  fi
}

# --- Report drift -------------------------------------------------------------

sync_workflows() {
  require_bundle
  install_workflows

  # Installed but unlisted: either a new third-party workflow that should be
  # saved, or an own workflow that should be tracked.
  local present listed extra
  present="$(installed_bundleids | sort -u)"
  listed="$(grep -v '^#' "$LIST" 2>/dev/null | cut -f1 | sort -u)"
  extra="$(comm -23 <(echo "$present") <(echo "$listed"))"

  if [[ -n "$extra" ]]; then
    echo "→ Installed but not in workflows.txt:"
    echo "$extra" | sed 's/^/    /'
    echo "  Run 'alfred.sh save' to record them."
  fi
}

# --- Point Alfred at this bundle ---------------------------------------------

link_bundle() {
  require_bundle
  if pgrep -x Alfred >/dev/null 2>&1; then
    echo "  ! Alfred is running. Quit it first — it rewrites its preferences on quit"
    echo "    and would overwrite this change."
    exit 1
  fi
  # The authoritative setting lives in Application Support, not in the defaults
  # domain — Alfred rewrites the defaults key from this file on launch, so
  # writing only the default silently reverts.
  local prefs="$HOME/Library/Application Support/Alfred/prefs.json"
  if [[ ! -f "$prefs" ]]; then
    echo "  ✗ $prefs not found — launch Alfred once first" >&2
    exit 1
  fi

  python3 -c '
import json, sys
prefs, folder, bundle = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(prefs))
d["current"] = bundle
d.setdefault("syncfolders", {})["5"] = folder
json.dump(d, open(prefs, "w"), indent=2)
' "$prefs" "$ALFRED_DIR" "$BUNDLE" || { echo "  ✗ failed to update $prefs" >&2; exit 1; }

  defaults write com.runningwithcrayons.Alfred-Preferences syncfolder -string "$ALFRED_DIR"
  echo "  ✓ Alfred sync folder set to $ALFRED_DIR"
  echo "    Start Alfred to pick it up."
}

# --- Main ---------------------------------------------------------------------

case "${1:-sync}" in
  setup)   link_bundle; install_workflows ;;
  save)    save_workflows ;;
  install) install_workflows ;;
  sync)    sync_workflows ;;
  link)    link_bundle ;;
  *)
    echo "Usage: $0 {setup|save|install|sync|link}"
    exit 1
    ;;
esac
