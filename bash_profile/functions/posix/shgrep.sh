#!/bin/sh

shgrep() {
  if [ -z "$*" ]; then
    warn "grep arguments required. cannot continue"
    return 1
  fi
  source_find '.' \
    -name "*.sh" \
    -print0 \
  | xargs -0 -r grep -E "$@"
}
