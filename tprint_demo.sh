#!/bin/sh

cpad() {
  # this function prints a ascii-colorized string right-padded to a given
  # minimum length -- it only considers the visible printing characters when
  # padding. these colorized sequences have a bunch of non-printing characters
  # that affect the string length, which frustrates formatting attempts with
  # printf or something like column
  desired_length="$1"; shift
  style="$1"; shift
  message="$*"

  # step 1, build a string which will be used later as a format arg for printf
  # it will look like this: '%s         ' with the proper number of trailing
  # spaces
  message_length="${#message}"
  padding_length=$(( (desired_length - message_length) + 2 )) # +2 covers "%s"

  # short-circuit if we don't have any padding to add
  if [ "$message_length" -gt "$desired_length" ]; then
    # overflow rather than truncate (for now)
    tprint "$style" "$message"
    return
  fi

  fmt="$(printf "%-${padding_length}s" '%s')"

  # step 2, print the colorized message using the format string
  printf "$fmt" "$(tprint -n "$style" "$message")"
}

colordump() {
  for color in black red green yellow blue magenta cyan white default; do
    for attr in dim- "" standout-  bright- underscore- reverse- blink-; do
      for bgcolor in "" -bgblack -bgred -bggreen -bgyellow -bgblue -bgmagenta -bgcyan -bgwhite -bgdefault; do
        style="${attr}${color}${bgcolor}"

        # cpad will properly pad the a colorized sequence with non-colorized trailing spaces
        # this doesn't always look great with some bgcolors
        cpad 28 "$style" "$style"

        # this printf approach pads the content with spaces (which will be colorized)
        # this looks bad with underlines
        #tprint -n "$style" "$(printf '%-28s' "$style")"

        printf ' '
      done
      printf '\n'
    done
    printf '\n'
  done
}

demo() {
  tprint -n yellow-blink '>>>>>>>>>>>>>>>>>>>>>'
  tprint -n red-standout-bright ' IMPORTANT '
  tprint yellow-blink '<<<<<<<<<<<<<<<<<<<<<'

  tprint -n cyan-standout Have you considered
  tprint -n green " a bale of turtles "
  tprint -n standout-underscore for president
  tprint magenta-bright ' ?'
  printf '\n'
}

main() {
  IMPORT=1
  . .bash_profile

  colordump
  demo
}

[ -n "$IMPORT" ] || main "$@"
