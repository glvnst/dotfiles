#!/bin/bash
# trying to make this stuff work with POSIX shell as much as possible

#
# installer-inserted functions (originating from other files)
#

# I-N-S-E-R-T - S-T-A-R-T

# I-N-S-E-R-T - E-N-D

#
# plumbing
#

_import() {
  # shellcheck source=/dev/null
  [ -f "$1" ] && IMPORT=1 . "$1"
}

warn() {
  printf '%s %s\n' "$(date '+%FT%T')" "$*" >&2
}

die() {
  warn 'FATAL:' "$@"
  exit 1
}

#
# support functions
#

#
# prompts and window titles
#

# Setup the shell window updates
pre_prompt() {
  # Update terminal window title
  printf '\e]0;%s\a' "${USER}@${HOSTNAME}:${PWD}"
}

pre_command() {
  local duration exit_code=$? 

  # update window title
  printf '\e]0;%s\a' "${USER}@${HOSTNAME}:${PWD} # ${BASH_COMMAND}"

  # useful for debugging timing issues
  (( PRE_COMMAND_DEBUG )) && printf \
    '%s: %s %s\n' "$(date '+%s.%N')" \
    "$BASH_COMMAND" \
    "$PRE_COMMAND_RESET" \
    >&2

  if [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ]; then
    # this is a PROMPT_COMMAND immediately following a PROMPT_COMMAND
    (( PRE_COMMAND_RESET )) && return

    # at the end of a complete command pipeline
    duration=$(( SECONDS - PRE_COMMAND_SECONDS ))
    if (( duration > PRE_COMMAND_DURATION_THRESHOLD )) || (( exit_code != 0 )); then
      local msg_style="dim-yellow-standout"
      (( exit_code != 0 )) && msg_style="dim-red-standout"
      tprint "$msg_style" "# $(date -R): exit ${exit_code} after $(fmt_duration $duration)" >&2
    fi
    PRE_COMMAND_RESET=1
  else
    # at the start of a command in a pipeline
    # tprint dim-white-standout "# $(date -R): $BASH_COMMAND" >&2
    if (( PRE_COMMAND_RESET )); then
      # ...and it is the first command in the pipeline
      PRE_COMMAND_SECONDS=$SECONDS
      PRE_COMMAND_RESET=0
    fi
  fi
}

main() {
  #
  # environment
  #

  # special portable non-fancy handling for important values
  export \
    PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/libexec" \
    USER="${USER:-$(id -un)}" \
    HOSTNAME="${HOSTNAME:-$(hostname)}" \
    LANG="${LANG:-en_US.UTF-8}" \
    LC_ALL="${LC_ALL:-en_US.UTF-8}" \
    TZ="${TZ:-Europe/Brussels}" \
    EDITOR="nano" \
    FTP_PASSIVE_MODE="1" \
    HISTFILESIZE="0" \
    HISTTIMEFORMAT="%FT%T : " \
    LESSHISTFILE="/dev/null" \
    LESSHISTSIZE="0" \
    PAGER="less" \
  ;

  unset \
    HISTFILE \
    PROMPT_COMMAND \
  ;

  PS1=$(
    if [ "$(id -u)" = "0" ]; then
      tprint -p red "\u"
    else
      tprint -p standout-green "\u"
    fi
    tprint -p dim '@'
    tprint -p cyan "\${HOSTNAME}"
    tprint -p dim ':'
    tprint -p standout-white "\${PWD}"
    printf ' '
    tprint -p bright-red '> '
  )
  PS2="\e[33m " # just color the ps2 text, better for copy-paste
  [ -n "$COLUMNS" ] && export COLUMNS

  # os-specific config
  case "$OSTYPE" in
    darwin*)
      [ -n "$NOCOLOR" ] || export CLICOLOR=1
      export SHELL_SESSION_HISTORY=0
      stty erase '^H'

      ;;

    linux*)
      true
      ;;

    *)
      true
      ;;
  esac

  #
  # shell vars
  #

  # make terminal window size changes work better
  shopt -s checkwinsize
  shopt -s autocd

  # enable Control-D to terminate the shell
  unset ignoreeof

  #
  # aliases
  #

  alias \
    "..=cd .." \
    "...=cd ../.." \
    "....=cd ../../.." \
    ".....=cd ../../../.." \
    "dl=pushd ~/Downloads/" \
    "dt=pushd ~/Desktop/" \
    "dumpcert=readcert" \
    "gits=git status" \
    "less=less -RiM" \
    "lg=ll | grep -iE" \
    "ll=ls -l -a " \
    "ls=ls -F -r -t -h" \
    "more=less -RiM" \
    "newer=find . -newerct" \
    "readcert=openssl x509 -text -issuer -subject -dates -hash -fingerprint -in" \
    "sl=ls" \
    "unixdate=date '+%s'" \
    "unixtime=unixdate" \
  ;

  # allow the imported files below to override
  _import ~/.bash_local
  _import ~/.profile_local

  PROMPT_COMMAND="pre_prompt"
  PRE_COMMAND_SECONDS=$SECONDS
  PRE_COMMAND_RESET=0
  PRE_COMMAND_DURATION_THRESHOLD=5
  trap pre_command DEBUG

  unset main
}

[ -n "$IMPORT" ] || main "$@"
