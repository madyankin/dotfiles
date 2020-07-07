#!/usr/bin/env bash
set -euo pipefail

cd $HOME

yadm add `yadm ls-tree master -r --name-only`
yadm ls-files --deleted -z | xargs -0 yadm rm >/dev/null 2>&2

yadm commit -m "Commited via cron $(date -u)" > /dev/null 2>&1
yadm push > /dev/null 2>&1
