#!/usr/bin/env bash
#
# Install the periodic dotfiles sync job.
#
# macOS: a launchd user agent in the gui/$UID domain. cron runs outside the
# GUI session, so `yadm push` there has no SSH_AUTH_SOCK and no keychain, and
# /usr/sbin/cron needs Full Disk Access. A launchd agent has both, and a
# StartInterval missed while asleep fires once on wake.
#
# Linux: the tracked crontab, as before.
set -euo pipefail

LABEL="name.madyankin.dotfiles.sync"
TEMPLATE="$HOME/.config/yadm/launchd/$LABEL.plist.template"
AGENT_DIR="$HOME/Library/LaunchAgents"
AGENT="$AGENT_DIR/$LABEL.plist"
CRONTAB="$HOME/.config/yadm/crontab"

install_launchd() {
  if [[ ! -f "$TEMPLATE" ]]; then
    echo "  ✗ $TEMPLATE not found" >&2
    exit 1
  fi

  mkdir -p "$AGENT_DIR" "$HOME/.local/state/dot"
  sed "s|@HOME@|$HOME|g" "$TEMPLATE" > "$AGENT"

  if ! plutil -lint "$AGENT" >/dev/null; then
    echo "  ✗ rendered plist is malformed: $AGENT" >&2
    exit 1
  fi

  # bootout first so a changed plist is actually picked up. Ignore the failure
  # when nothing is loaded yet.
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$AGENT"

  echo "→ Loaded launchd agent $LABEL"
  launchctl print "gui/$UID/$LABEL" | sed -n 's/^[[:space:]]*\(state = .*\)/  \1/p'

  # The crontab entry this replaces would otherwise double up.
  # Only an UNCOMMENTED line double-schedules. The tracked crontab keeps the
  # entry commented for reference, and matching it was a false positive.
  if crontab -l 2>/dev/null | grep -qE '^[[:space:]]*[^#[:space:]].*commit-and-push\.sh'; then
    echo "  ! the user crontab still references commit-and-push.sh"
    echo "    remove it with: crontab -e"
  fi
}

install_crontab() {
  if [[ ! -f "$CRONTAB" ]]; then
    echo "  ✗ $CRONTAB not found" >&2
    exit 1
  fi
  crontab "$CRONTAB"
  echo "→ Installed crontab:"
  crontab -l | sed 's/^/  /'
}

case "$(uname -s)" in
  Darwin) install_launchd ;;
  *)      install_crontab ;;
esac
