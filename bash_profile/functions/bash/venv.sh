#!/bin/bash

venv() {
  if type deactivate >/dev/null 2>&1; then
    warn "deactivating current venv"
    deactivate
    return
  fi

  if [ -d 'venv' ]; then
    warn "activating existing venv"
    # shellcheck source=/dev/null
    source venv/bin/activate
    return
  fi

  if ! [ -a 'venv' ]; then
    warn "creating, activating, and updating new venv"
    python3 -m venv ./venv || return 1
    # shellcheck source=/dev/null
    source ./venv/bin/activate || return 1
    pip install --upgrade pip || return 1
    return 0
  fi
}
