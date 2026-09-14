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

  local tmp own=0 third=0
  tmp="$(mktemp)"
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

  # Sort the body only, so the header stays at the top.
  {
    echo "# Third-party Alfred workflows, reinstalled by \`alfred.sh install\`."
    echo "# Own workflows are tracked in git instead and are not listed here."
    echo "# bundleid<TAB>name<TAB>version<TAB>source"
    sort -t'	' -k2,2 "$tmp"
  } > "$LIST"
  rm -f "$tmp"
  echo "  ✓ $third third-party workflows listed"
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
  local id="$1" name="$2" src="$3" repo url tmp

  if [[ "$src" =~ github\.com/([^/]+)/([^/]+) ]]; then
    repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]%/}"
    url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
           | grep -o '"browser_download_url": *"[^"]*\.alfredworkflow"' \
           | head -1 | sed 's/.*": *"//;s/"$//')"
    if [[ -n "$url" ]]; then
      tmp="$(mktemp -d)/${name//\//-}.alfredworkflow"
      if curl -fsSL -o "$tmp" "$url"; then
        open "$tmp"        # Alfred takes over and imports it
        echo "  ↓ $name — downloaded, Alfred is importing it"
        return 0
      fi
    fi
  fi

  echo "  ! $name — no downloadable release found; opening $src"
  open "$src"
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

  [[ $missing -eq 0 ]] && echo "  ✓ all listed workflows already installed"
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
