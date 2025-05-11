#!/bin/sh

workflowgrep() {
  if [ -z "$*" ]; then
    warn "grep arguments required. cannot continue"
    return 1
  fi
  source_find '.' \
    -name '*.y*ml' \
    -path '*/.git*/workflows/*' \
    -print0 \
  | xargs -0 -r rg "$@"
}
