#!/bin/bash

tprint() {
  # Usage: tprint [-p|-n] [-d] spec message [...]
  # spec is one or more dash-separated keywords such as
  # bright-underscore-magenta-bgblue
  # messge is the message to print
  # additional arguments will be concatenated into the message

  local \
    OPTIND \
    opt \
    output_mode \
    tprint_debug \
    term_codes="" \
  ;

  # arg parse
  while getopts "dnp" opt; do
    case "$opt" in
      'p')
        output_mode='bash-prompt'
        ;;

      'n')
        output_mode='no-newline'
        ;;

      'd')
        tprint_debug='1'
        ;;

      *)
        warn "tprint: Unknown option ${opt} IGNORING"
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))
  local spec="$1"; shift
  local message="$*"

  # spec parse
  local old_IFS="$IFS"
  IFS="-"
  local keyword_item
  for keyword_item in \
    'reset:0' \
    'bright:1' \
    'dim:2' \
    'standout:3' \
    'underscore:4' \
    'blink:5' \
    'reverse:6' \
    'black:30' \
    'red:31' \
    'green:32' \
    'yellow:33' \
    'blue:34' \
    'magenta:35' \
    'cyan:36' \
    'white:37' \
    'default:38' \
    'fgblack:30' \
    'fgred:31' \
    'fggreen:32' \
    'fgyellow:33' \
    'fgblue:34' \
    'fgmagenta:35' \
    'fgcyan:36' \
    'fgwhite:37' \
    'fgdefault:38' \
    'bgblack:40' \
    'bgred:41' \
    'bggreen:42' \
    'bgyellow:43' \
    'bgblue:44' \
    'bgmagenta:45' \
    'bgcyan:46' \
    'bgwhite:47' \
    'bgdefault:48' \
  ; do
    local keyword="${keyword_item%%:*}"
    local code="${keyword_item##*:}"
    local substr
    # search the entire spec for this keyword and add it if it exists
    for substr in $spec; do
      [ "$substr" = "$keyword" ] && term_codes="${term_codes}${code};"
    done
  done
  IFS="$old_IFS"

  # strip the trailing ; if needed
  term_codes="${term_codes%%;}"

  [ -n "$tprint_debug" ] && printf "term codes: %s\n" "$term_codes" >&2

  # print
  if [ "$output_mode" = "bash-prompt" ]; then
    printf '\[\e[%sm\]%s\[\e[0m\]' "$term_codes" "$message"
  else
    printf '\e[%sm%s\e[0m' "$term_codes" "$message"
    [ "$output_mode" != "no-newline" ] && printf '\n'
  fi

}
