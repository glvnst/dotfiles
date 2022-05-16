#!/bin/sh

collect() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$#" -lt 2 ]; then
    printf '%s\n' \
      "Usage: collect targetpath sourcepath [...]" \
      "" \
      "A combination of mv and mkdir. Creates the given target directory" \
      "if necessary then moves the given files into the target." \
      "" \
      "E.G.:" \
      "collect pdfs *.pdf ~/Desktop/*.pdf" \
      ""\
    >&2
    return
  fi
  target=$1; shift

  # Make the directory if necessary
  [ -d "$target" ] \
    || mkdir -p -- "$target" \
    || die "couldn't create target directory ${target}"

  # collect the things into the thing
  mv -iv -- "$@" "${target}/" \
    || die "couldn't move the specified items into ${target}"
}
