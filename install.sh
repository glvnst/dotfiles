#!/bin/sh

usage() {
  self="$(basename "$0")"

  printf '%s\n' \
    "Usage: $self [install]" \
    "" \
    "Install the files in this directory (.*) into $HOME" \
    ""

  exit 1
}

die() {
  warn "$* EXITING"
  exit 1
}

warn() {
  printf '%s %s\n' "$(date '+%FT%T')" "$*" >&2
}

main() {
  [ "$*" = "install" ] || usage

  { 
    [ -n "$HOME" ] &&
    [ -d "$HOME" ] &&
    [ "$HOME" != '/' ];
  } || warn "Home directory not found"

  find . -mindepth 1 -maxdepth 1 -type f -name '.*' \
  | while read -r rawfile; do
    file="$(basename "$rawfile")"
    link_path="${HOME}/${file}"
    link_target="$(pwd)/${file}"

    if [ -h "$link_path" ]; then
      existing_target="$(readlink "$link_path")"

      if [ "$existing_target" = "$link_target" ]; then
        printf '%s exists and points to the right place\n' "$link_path"
        continue
      fi

      printf "%s exists but points to %s. re-linking\n" \
        "$link_path" \
        "$existing_target"
      rm -v "${link_path}" | sed 's/^/rm: /'
    else
      if [ -e "$link_path" ]; then
        printf "%s exists but is NOT a symlink, skipping" "$link_path"
        continue
      fi
    fi

    /bin/ln -s -v "$link_target" "$link_path" | sed 's/^/ln: /'
    printf '\n'
  done
}

[ -n "$IMPORT" ] || main "$@"