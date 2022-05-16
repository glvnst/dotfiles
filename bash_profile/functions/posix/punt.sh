#!/bin/sh

# copy and paste files between terminal windows;
# usage: punt file_or_dir [..]
# it prints a blob of base64 to the terminal. copy and paste it into another
# terminal window. the files appear. finding the platform's correct base64
# decode argument is the hardest part
punt() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf '%s\n' \
      "Usage: punt [file_or_dir [..]]" \
      "copy and paste files between terminal windows; punt prints a" \
      "base64-encoded tar file of the files/directories you give it. it" \
      "wraps this in a convenient copy-and-pastable here-doc which you can" \
      "use to copy and paste files between machines. if you call punt with" \
      "no arguments it prints the punt function itself so that you can " \
      "easily share it with remote machines" \
    ;
    return
  fi
  if [ "$#" -eq 0 ]; then
    # print the punt function itself -- in case you want to use it on other
    # machines
    type punt | expand | grep -Ev "^punt is a function$"
    return
  fi
  printf '\n'
  printf ' %s\n' \
    '(' \
    'if (base64 --decode </dev/null 2>/dev/null); then' \
    ' base64 --decode | tar -xvzf -;' \
    'elif (base64 -d </dev/null 2>/dev/null); then' \
    ' base64 -d | tar -xvzf -;' \
    'else' \
    ' cat >/dev/null;' \
    ' return 1;' \
    "fi; ) <<'_PUNT_'"
  tar -czf - "$@" 2>/dev/null | base64 | fold -w 80
  printf '%s\n' '_PUNT_' ''
}
