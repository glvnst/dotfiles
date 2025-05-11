#!/bin/sh

composegrep() {
  if [ -z "$*" ]; then
    warn "grep arguments required. cannot continue"
    return 1
  fi
  source_find "." \
    '(' \
      -name "docker-compose.yml" \
      -or -name "docker-compose.*.yml" \
      -or -name "compose.yml" \
      -or -name "compose.*.yml" \
    ')' \
    -print0 \
  | xargs -0 -r grep -E "$@"
}
