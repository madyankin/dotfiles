#!/usr/bin/env bash
set -euo pipefail

cd $HOME/Documents/Org

git ls-files --deleted -z | xargs -0 git rm >/dev/null 2>&1

git add . >/dev/null 2>&1
git commit -m "Commited via cron $(date)" > /dev/null 2>&1
