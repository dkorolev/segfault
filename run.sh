#!/bin/bash

set -e

if [[ $UID == 0 || $EUID == 0 ]] ; then
  echo 'please do not run as root.'
  exit 1
elif ! ( [ "$EUID" -eq 0 ] || SUDO_ASKPASS=/bin/false sudo -A /bin/true >/dev/null 2>&1) ; then
  echo 'need sudo.'
  exit 1
fi

if ! gdb --version >/dev/null ; then
  sudo apt-get install -y gdb
fi

SAVE="$(cat /proc/sys/kernel/core_pattern)"

ulimit -c unlimited

mkdir -p /tmp

echo "$PWD/binary.core" | sudo tee /proc/sys/kernel/core_pattern >/dev/null

if g++ -o binary -g code.cc && ./binary ; then
  echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null >/dev/null
  echo 'nah, this should have crashed.'
else
  echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null
  echo 'yay, crashed!'
  echo
  echo 'thread apply all bt' | gdb binary binary.core
  rm -f binary binary.core
fi
