#!/bin/bash

set -e

if [[ "$(uname)" != 'Darwin' ]] ; then
  if [[ $UID == 0 || $EUID == 0 ]] ; then
    echo 'please do not run as root.'
    exit 1
  elif ! ( [ "$EUID" -eq 0 ] || SUDO_ASKPASS=/bin/false sudo -A /bin/true >/dev/null 2>&1) ; then
    echo 'need sudo.'
    exit 1
  fi
fi

if [[ "$(uname)" != 'Darwin' ]] ; then
  DEBUGGER=gdb
else
  DEBUGGER=lldb
fi

if ! $DEBUGGER --version >/dev/null 2>&1 ; then
  if [[ "$(uname)" != 'Darwin' ]] ; then
    echo '::group::apt-get install -y gdb'
    sudo apt-get install -y gdb
    echo '::endgroup::'
  else
    echo '::group::brew install llvm'
    brew install llvm
    echo '::endgroup::'
  fi
fi

if [[ "$(uname)" != 'Darwin' ]] ; then
  SAVE="$(cat /proc/sys/kernel/core_pattern)"
fi

ulimit -c unlimited

mkdir -p /tmp

if [[ "$(uname)" != 'Darwin' ]] ; then
  echo "$PWD/binary.core" | sudo tee /proc/sys/kernel/core_pattern >/dev/null
fi

echo '::group::./binary'
if g++ -o binary -g code.cc && ./binary ; then
  echo '::endgroup::'
  if [[ "$(uname)" != 'Darwin' ]] ; then
    echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null >/dev/null
  fi
  echo 'nah, this should have crashed.'
else
  echo '::endgroup::'
  if [[ "$(uname)" != 'Darwin' ]] ; then
    echo "$SAVE" | sudo tee /proc/sys/kernel/core_pattern >/dev/null
  fi
  echo 'yay, crashed!'
  echo
  if [[ "$(uname)" == 'Darwin' ]] ; then
    CORE="$(find /cores -name 'core.*' | head -n 1)"
  else
    CORE="$(find . -name 'binary.core*' | head -n 1)"
  fi
  if [ -n "$CORE" ] ; then
    echo "::group::${DEBUGGER}"
    if [[ "$(uname)" != 'Darwin' ]] ; then
      echo -en 'thread apply all bt\nquit\n' | $DEBUGGER binary "$CORE"
    else
      echo bt | $DEBUGGER binary -c "$CORE"
    fi
    echo '::endgroup::'
    rm -f "$CORE"
  else
    echo 'nah, no core file.'
  fi
  rm -f binary
fi
