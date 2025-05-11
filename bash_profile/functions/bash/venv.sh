#!/bin/bash

venv() {
  local venv_dirname=".venv"

  if type deactivate >/dev/null 2>&1; then
    warn "deactivating current venv"
    deactivate
    return
  fi

  if [ -d "${venv_dirname}" ]; then
    warn "activating existing venv"
    # shellcheck source=/dev/null
    source "${venv_dirname}/bin/activate"
    return
  fi

  if ! [ -a "${venv_dirname}" ]; then
    warn "creating, activating, and updating new venv"
    logrun python3 -m venv "${venv_dirname}" || return 1
    # shellcheck source=/dev/null
    source "${venv_dirname}/bin/activate" || return 1
    logrun pip install --upgrade pip || return 1

    set --
    for requirements_file in requirements*txt; do
      if [ -f "${requirements_file}" ]; then
        set -- "$@" -r "${requirements_file}"
      fi
    done
    if [ "$#" != "0" ]; then
      warn "installing deps from requirements files"
      logrun pip install "$@" || return 2
    fi

    return 0
  fi
}
