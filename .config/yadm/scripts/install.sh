#!/usr/bin/env bash
#
# Software install wizard. Re-runnable at any time to change what is installed.
#
# Groups are exactly the ones this config already defines. A group is selected
# as a whole via <All> (the default) or expanded to toggle individual packages.
#
# REMOVAL IS SCOPED. The manifests describe ~40 packages; this machine has many
# more installed that this config has never claimed. A package is only ever
# removed when it appears in some group's manifest AND is not in the current
# selection. Anything unmanaged is left alone.
#
# macOS ships bash 3.2 — no associative arrays, no `declare -A`. Keep it 3.2-safe.

set -uo pipefail

YADM_DIR="$HOME/.config/yadm"
PKG_DIR="$YADM_DIR/packages"
STATE="$PKG_DIR/.selection"          # untracked, machine-specific

PKG_GROUPS="essentials personal claude codex goose"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ---------------------------------------------------------------- manifests --

# Groups backed by an npm global rather than a Brewfile.
npm_pkg() {
  case "$1" in
    claude) echo "@anthropic-ai/claude-code" ;;
    codex)  echo "@openai/codex" ;;
    *)      return 1 ;;
  esac
}

group_desc() {
  case "$1" in
    essentials) echo "CLI, fonts, editors, everyday apps" ;;
    personal)   echo "music, journaling, books, backups" ;;
    claude)     echo "Claude Code (Anthropic)" ;;
    codex)      echo "Codex (OpenAI)" ;;
    goose)      echo "Goose (Block)" ;;
  esac
}

# Every package in a group, one per line: "kind<TAB>name<TAB>id"
# kind is brew | cask | mas | npm
group_packages() {
  local g="$1" bf="$PKG_DIR/Brewfile.$g"
  if npm_pkg "$g" >/dev/null 2>&1; then
    printf 'npm\t%s\t%s\n' "$g" "$(npm_pkg "$g")"
    return
  fi
  [[ -f "$bf" ]] || return 0
  while IFS= read -r line; do
    case "$line" in
      brew\ \"*) printf 'brew\t%s\t\n' "$(echo "$line" | sed 's/^brew "\([^"]*\)".*/\1/')" ;;
      cask\ \"*) printf 'cask\t%s\t\n' "$(echo "$line" | sed 's/^cask "\([^"]*\)".*/\1/')" ;;
      mas\ \"*)  printf 'mas\t%s\t%s\n' \
                   "$(echo "$line" | sed 's/^mas "\([^"]*\)".*/\1/')" \
                   "$(echo "$line" | sed 's/.*id: *\([0-9]*\).*/\1/')" ;;
    esac
  done < "$bf"
}

# ------------------------------------------------------------ install state --

BREW_FORMULAE=""; BREW_CASKS=""; MAS_IDS=""
load_installed() {
  command -v brew >/dev/null 2>&1 && {
    BREW_FORMULAE="$(brew list --formula 2>/dev/null)"
    BREW_CASKS="$(brew list --cask 2>/dev/null)"
  }
  command -v mas >/dev/null 2>&1 && MAS_IDS="$(mas list 2>/dev/null | awk '{print $1}')"
}

is_installed() {  # kind name id
  case "$1" in
    brew) grep -qx -- "$2" <<<"$BREW_FORMULAE" ;;
    cask) grep -qx -- "$2" <<<"$BREW_CASKS" ;;
    mas)  grep -qx -- "$3" <<<"$MAS_IDS" ;;
    npm)  command -v "$2" >/dev/null 2>&1 ;;
  esac
}

# ------------------------------------------------------------------- state ---

# Selection is one "group=All" / "group=pkg,pkg" / "group=" line per group.
sel_get() {
  [[ -f "$STATE" ]] && grep "^$1=" "$STATE" 2>/dev/null | head -1 | cut -d= -f2- || true
}

sel_set() {  # group value
  local g="$1" v="$2" tmp known
  tmp="$(mktemp)"
  [[ -f "$STATE" ]] && grep -v "^$g=" "$STATE" 2>/dev/null | grep -v "^$g#known=" > "$tmp"
  echo "$g=$v" >> "$tmp"
  # Snapshot the manifest as it stands now, so a later run can tell which
  # packages appeared in the Brewfile after this selection was made.
  known="$(group_packages "$g" | cut -f2 | paste -sd, -)"
  echo "$g#known=$known" >> "$tmp"
  sort -o "$tmp" "$tmp"
  mv "$tmp" "$STATE"
}

# Packages in the manifest that were not there when the selection was last
# written. An <All> group absorbs them; an explicit group does not, so they
# have to be reported rather than silently never installed.
new_since_last_run() {  # group -> comma list
  local g="$1" known out="" p
  known="$(sel_get "${g}#known")"
  [[ -z "$known" ]] && return 0
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    grep -q "\(^\|,\)$p\(,\|$\)" <<<"$known" || out="${out:+$out, }$p"
  done <<<"$(group_packages "$g" | cut -f2)"
  echo "$out"
}

# First run: seed the selection from what is actually installed, so the wizard
# opens on reality rather than a blank prompt and cannot propose mass removal.
seed_state() {
  [[ -f "$STATE" ]] && return
  local g total inst line kind name id
  for g in $PKG_GROUPS; do
    total=0; inst=0
    while IFS=$'\t' read -r kind name id; do
      [[ -z "$kind" ]] && continue
      total=$((total+1))
      is_installed "$kind" "$name" "$id" && inst=$((inst+1))
    done <<<"$(group_packages "$g")"
    if   [[ $total -eq 0 || $inst -eq 0 ]]; then sel_set "$g" ""
    elif [[ $inst -eq $total ]];            then sel_set "$g" "All"
    else
      line=""
      while IFS=$'\t' read -r kind name id; do
        [[ -z "$kind" ]] && continue
        is_installed "$kind" "$name" "$id" && line="${line:+$line,}$name"
      done <<<"$(group_packages "$g")"
      sel_set "$g" "$line"
    fi
  done
}

is_pkg_selected() {  # group pkgname
  local s; s="$(sel_get "$1")"
  [[ "$s" == "All" ]] && return 0
  [[ -z "$s" ]] && return 1
  grep -q "\(^\|,\)$2\(,\|$\)" <<<"$s"
}

# ------------------------------------------------------------------- render --

group_counts() {  # group -> "total installed selected"
  local g="$1" total=0 inst=0 selc=0 kind name id
  while IFS=$'\t' read -r kind name id; do
    [[ -z "$kind" ]] && continue
    total=$((total+1))
    is_installed "$kind" "$name" "$id" && inst=$((inst+1))
    is_pkg_selected "$g" "$name" && selc=$((selc+1))
  done <<<"$(group_packages "$g")"
  echo "$total $inst $selc"
}

show_menu() {
  local i=0 g total inst selc mark state fresh
  echo ""
  echo "╭──────────────────────────────────────────────────────────────╮"
  echo "│                    Software Install Wizard                   │"
  echo "╰──────────────────────────────────────────────────────────────╯"
  echo ""
  for g in $PKG_GROUPS; do
    i=$((i+1))
    read -r total inst selc <<<"$(group_counts "$g")"
    if   [[ $selc -eq 0 ]];      then mark=" "
    elif [[ $selc -eq $total ]]; then mark="x"
    else                              mark="~"; fi
    [[ "$(sel_get "$g")" == "All" ]] && state="<All>" || state="$selc of $total"
    printf "  %d. [%s] %-11s %-8s  %2d pkg · %2d installed   %s\n" \
      "$i" "$mark" "$g" "$state" "$total" "$inst" "$(group_desc "$g")"
  done
  echo ""
  for g in $PKG_GROUPS; do
    [[ "$(sel_get "$g")" == "All" ]] && continue
    fresh="$(new_since_last_run "$g")"
    [[ -n "$fresh" ]] && echo "  ! $g: new in the manifest since last run — not selected: $fresh"
  done
  echo "  <n> toggle group   e <n> expand   a apply   d dry-run   q quit"
}

show_group() {
  local g="$1" i=0 kind name id box inst
  echo ""
  echo "  ── $g ── $(group_desc "$g")"
  [[ "$(sel_get "$g")" == "All" ]] && echo "     mode: <All> (new packages added to the manifest are included)"
  echo ""
  while IFS=$'\t' read -r kind name id; do
    [[ -z "$kind" ]] && continue
    i=$((i+1))
    is_pkg_selected "$g" "$name" && box="x" || box=" "
    is_installed "$kind" "$name" "$id" && inst="✓" || inst="·"
    printf "    %2d. [%s] %s %-34s (%s)\n" "$i" "$box" "$inst" "$name" "$kind"
  done <<<"$(group_packages "$g")"
  echo ""
  echo "     ✓ installed   · not installed"
  echo "     <n> toggle package   all   none   b back"
}

# ------------------------------------------------------------------- apply ---

# Everything any manifest mentions — the universe removal may consider.
all_managed() {
  local g kind name id
  for g in $PKG_GROUPS; do
    while IFS=$'\t' read -r kind name id; do
      [[ -z "$kind" ]] && continue
      printf '%s\t%s\t%s\n' "$kind" "$name" "$id"
    done <<<"$(group_packages "$g")"
  done | sort -u
}

# Union of selected packages across ALL groups. A package selected in one group
# and deselected in another is kept — this is why removal uses the union.
selected_union() {
  local g kind name id
  for g in $PKG_GROUPS; do
    while IFS=$'\t' read -r kind name id; do
      [[ -z "$kind" ]] && continue
      is_pkg_selected "$g" "$name" && printf '%s\t%s\t%s\n' "$kind" "$name" "$id"
    done <<<"$(group_packages "$g")"
  done | sort -u
}

plan() {  # prints "INSTALL kind name id" / "REMOVE kind name id"
  local kind name id sel
  sel="$(selected_union)"
  while IFS=$'\t' read -r kind name id; do
    [[ -z "$kind" ]] && continue
    is_installed "$kind" "$name" "$id" || printf 'INSTALL\t%s\t%s\t%s\n' "$kind" "$name" "$id"
  done <<<"$sel"
  while IFS=$'\t' read -r kind name id; do
    [[ -z "$kind" ]] && continue
    grep -q "^$kind	$name	" <<<"$sel" && continue
    is_installed "$kind" "$name" "$id" && printf 'REMOVE\t%s\t%s\t%s\n' "$kind" "$name" "$id"
  done <<<"$(all_managed)"
}

show_plan() {
  local p ins rem
  p="$(plan)"
  ins="$(grep '^INSTALL' <<<"$p")"; rem="$(grep '^REMOVE' <<<"$p")"
  echo ""
  if [[ -z "$ins" && -z "$rem" ]]; then
    echo "  Nothing to do — the machine already matches the selection."
    return 1
  fi
  if [[ -n "$ins" ]]; then
    echo "  Install ($(wc -l <<<"$ins" | tr -d ' ')):"
    awk -F'\t' '{printf "    + %-34s (%s)\n", $3, $2}' <<<"$ins"
  fi
  if [[ -n "$rem" ]]; then
    echo ""
    echo "  REMOVE ($(wc -l <<<"$rem" | tr -d ' ')):"
    awk -F'\t' '{printf "    - %-34s (%s)\n", $3, $2}' <<<"$rem"
    echo ""
    echo "  Only packages named in a manifest are ever removed."
    echo "  Everything else installed on this machine is left untouched."
  fi
  return 0
}

apply() {
  show_plan || return 0
  echo ""
  read -rp "  Apply this plan? [y/N] " ok
  [[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "  Cancelled."; return 0; }

  local action kind name id
  while IFS=$'\t' read -r action kind name id; do
    [[ -z "${action:-}" ]] && continue
    case "$action:$kind" in
      INSTALL:brew) brew install "$name" ;;
      INSTALL:cask) brew install --cask "$name" ;;
      INSTALL:mas)  ensure_mas_login && mas install "$id" ;;
      INSTALL:npm)  npm install -g "$id" ;;
      REMOVE:brew)  brew uninstall "$name" ;;
      REMOVE:cask)  brew uninstall --cask --force "$name" ;;
      REMOVE:mas)   echo "  ! $name is a Mac App Store app — remove it from Finder by hand" ;;
      REMOVE:npm)   npm uninstall -g "$id" ;;
    esac
  done <<<"$(plan)"

  load_installed
  echo ""
  echo "  ✓ Done."
}

MAS_LOGIN_CHECKED=false
ensure_mas_login() {
  $MAS_LOGIN_CHECKED && return 0
  MAS_LOGIN_CHECKED=true
  command -v mas >/dev/null 2>&1 || return 1
  mas account >/dev/null 2>&1 && return 0
  echo "  Not signed in to the Mac App Store — opening App Store..."
  open -a "App Store"
  read -rp "  Press Enter after signing in..."
}

# -------------------------------------------------------------------- main ---

command -v brew >/dev/null 2>&1 || {
  echo "Homebrew is required. Install it from https://brew.sh first." >&2
  exit 1
}

load_installed
seed_state

if $DRY_RUN; then
  show_menu
  show_plan
  exit 0
fi

while true; do
  show_menu
  read -rp "  > " cmd arg
  case "$cmd" in
    q|Q) echo "  Nothing applied."; exit 0 ;;
    a|A) apply ;;
    d|D) show_plan ;;
    e|E)
      set -- $PKG_GROUPS
      g="$(eval echo \${$arg:-})"
      [[ -z "$g" ]] && { echo "  No such group."; continue; }
      while true; do
        show_group "$g"
        read -rp "     > " gc garg
        case "$gc" in
          b|B) break ;;
          all) sel_set "$g" "All" ;;
          none) sel_set "$g" "" ;;
          ''|*[!0-9]*) echo "     ?" ;;
          *)
            pkg="$(group_packages "$g" | sed -n "${gc}p" | cut -f2)"
            [[ -z "$pkg" ]] && { echo "     No such package."; continue; }
            cur="$(sel_get "$g")"
            if [[ "$cur" == "All" ]]; then
              cur="$(group_packages "$g" | cut -f2 | paste -sd, -)"
            fi
            if is_pkg_selected "$g" "$pkg"; then
              cur="$(tr ',' '\n' <<<"$cur" | grep -vx "$pkg" | paste -sd, -)"
            else
              cur="${cur:+$cur,}$pkg"
            fi
            sel_set "$g" "$cur"
            ;;
        esac
      done
      ;;
    ''|*[!0-9]*) echo "  ?" ;;
    *)
      set -- $PKG_GROUPS
      g="$(eval echo \${$cmd:-})"
      [[ -z "$g" ]] && { echo "  No such group."; continue; }
      [[ -n "$(sel_get "$g")" ]] && sel_set "$g" "" || sel_set "$g" "All"
      ;;
  esac
done
