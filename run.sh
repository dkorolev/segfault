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

echo "CORE FILE PATH: $(cat /proc/sys/kernel/core_pattern)"

if g++ -o binary -g code.cc && ./binary ; then
  echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null >/dev/null
  echo 'nah, this should have crashed.'
else
  echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null
  echo 'yay, crashed!'
  echo
  ls -las
  echo
  CORE="$(find . -name 'binary.core*' | head -n 1)"
  if [ -n "$CORE" ] ; then
    gdb -q -ex "thread apply all bt" -ex "quit" binary "$CORE"
    rm -f "$CORE"
  fi
  rm -f binary
fi
