#!/bin/bash

source_find() {
 local search_dir="$1"; shift
  if [ -z "$search_dir" ]; then
    warn 'source_find: requires a search directory argument, cannot continue'
    return 1
  fi
  if [ -z "$*" ]; then
    warn "source_find: requires find arguments (for example: -name '*.py'), " \
      "cannot continue"
    return 1
  fi

  # temp redirecting outputs so i can grep-out some stderr output
  # via https://unix.stackexchange.com/a/3540
  {
    find "$search_dir" -not '(' '(' \
      -name '*.egg' \
      -or -name '*.egg-info' \
      -or -name '*_cache' \
      -or -name '.AppleDouble' \
      -or -name '.DS_Store' \
      -or -name '.Spotlight-V100' \
      -or -name '.Trashes' \
      -or -name '.cache' \
      -or -name '.eggs' \
      -or -name '.git' \
      -or -name '.hypothesis' \
      -or -name '.idea' \
      -or -name '.ipynb_checkpoints' \
      -or -name '.mypy_cache' \
      -or -name '.npm' \
      -or -name '.pybuilder' \
      -or -name '.pytest_cache' \
      -or -name '.sass-cache' \
      -or -name '.sessions' \
      -or -name '.sourcemint' \
      -or -name '.svn' \
      -or -name '.venv' \
      -or -name '.vs' \
      -or -name '.vscode' \
      -or -name '.yarn-integrity' \
      -or -name '__pycache__' \
      -or -name '__pypackages__' \
      -or -name 'build' \
      -or -name 'cache' \
      -or -name 'eggs' \
      -or -name 'env' \
      -or -name 'logs' \
      -or -name 'node_modules' \
      -or -name 'restore' \
      -or -name 'site-packages' \
      -or -name 'vendor' \
      -or -name 'venv' \
      -or -name 'venv.bak' \
      -or -name 'wheels' \
    ')' -prune ')' \
    -type f \
    "$@" \
    2>&1 1>&3 \
    | grep -vF 'Operation not permitted';
  } 3>&1
}
