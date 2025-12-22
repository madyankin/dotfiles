#!/usr/bin/env bash
set -euo pipefail

source $HOME/.zshenv
cd $HOME

yadm add -u

yadm commit -m "Commited via cron $(date -u)" > /dev/null 2>&1
yadm pull --rebase > /dev/null 2>&1
yadm push > /dev/null 2>&1
