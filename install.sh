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
        warn "${link_path} exists and points to the right place"
        continue
      fi

      warn "${link_path} exists but points to ${existing_target}, unlinking"
      rm -- "${link_path}" || die "could not unlink ${link_path}"
    else
      if [ -e "$link_path" ]; then
        warn "${link_path} exists but is NOT a symlink, skipping"
        continue
      fi
    fi

    /bin/ln -s "$link_target" "$link_path" \
    || dies "could not link ${link_path}"
  done
}

[ -n "$IMPORT" ] || main "$@"
