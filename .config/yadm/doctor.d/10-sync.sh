#!/usr/bin/env bash
# dot:check=periodic dotfiles sync is actually scheduled and running
set -uo pipefail
rc=0
LABEL="name.madyankin.dotfiles.sync"

if launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1; then
  ok "launchd agent loaded: $LABEL"
else
  err "launchd agent NOT loaded: $LABEL"
  note "fix: dot cron install"
  rc=1
fi

# The failure this exists to catch: the tracked crontab said the job was on
# while the live crontab had it commented out, so nothing synced for weeks.
if crontab -l 2>/dev/null | grep -q '^[^#]*commit-and-push.sh'; then
  warn "the user crontab ALSO runs commit-and-push.sh — it will double up with launchd"
elif crontab -l 2>/dev/null | grep -q 'commit-and-push.sh'; then
  ok "crontab entry present but commented out (launchd owns this now)"
fi

last="$(yadm log -1 --format=%ct --grep="chore(sync): .*$(hostname -s)" 2>/dev/null)"
if [[ -n "$last" ]]; then
  age=$(( ( $(date +%s) - last ) / 3600 ))
  if [[ $age -le 26 ]]; then
    ok "last sync commit from this host: ${age}h ago"
  else
    warn "last sync commit from this host: ${age}h ago (expected <26h)"
  fi
else
  warn "no chore(sync) commit from this host yet"
fi

exit $rc
