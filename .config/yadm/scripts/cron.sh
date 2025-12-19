#!/usr/bin/env bash

cat $HOME/.crontab | crontab -
crontab -l
