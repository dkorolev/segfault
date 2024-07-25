#!/bin/bash

set -e

if [[ $UID == 0 || $EUID == 0 ]] ; then
  echo 'please do not run as root.'
  exit 1
elif ! ( [ "$EUID" -eq 0 ] || SUDO_ASKPASS=/bin/false sudo -A /bin/true >/dev/null 2>&1) ; then
  echo 'need sudo.'
  exit 1
fi

TS=$(date +%s)

SAVE="$(cat /proc/sys/kernel/core_pattern)"

ulimit -c unlimited

mkdir -p /tmp

echo "/tmp/core.${TS}.%e.tmp" | sudo tee /proc/sys/kernel/core_pattern >/dev/null

if g++ -g code.cc && ./a.out ; then
  echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null >/dev/null
  echo 'nah, this should have crashed.'
else
  echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null
  echo 'yay, crashed!'
  echo
  echo 'thread apply all bt' | gdb a.out "/tmp/core.${TS}.a.out.tmp"
  rm "/tmp/core.${TS}.a.out.tmp"
fi
