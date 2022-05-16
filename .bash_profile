#!/bin/bash
# trying to make this stuff work with POSIX shell as much as possible

#
# installer-inserted functions (originating from other files)
#

# I-N-S-E-R-T - S-T-A-R-T

# inserted from bash_profile/functions/bash/fmt_duration.sh

fmt_duration() {
  # documentation repeated here for copy/paste into other scripts
  # takes a number of seconds and prints it in years, hours, minutes, seconds
  #
  # for example:
  #   fmt_duration 35000000
  # yields:
  #   1 year, 39 days, 20 hours, 13 minutes, 20 seconds
  #
  # Note: by default 1 year is treated as 365.25 days to account for leap years
  #
  # You may optionally specify the labeled increments to use when formatting
  # the duration. Use "singular/plural:seconds" for each increment. For example
  # if you only want duration specified in days and hours use the increments
  # day/days:86400 hour/hours:3600.
  #
  # The complete example call:
  #   fmt_duration 1216567 day/days:86400 hour/hours:3600
  # yields:
  #   14 days, 1 hour
  #
  # This function makes heavy use of POSIX shell Parameter Expansion for
  # string manipulations, see:
  # https://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html

  local seconds=${1:-0}; shift
  local labeled_increments=${*:-'year/years:31557600' \
                                'day/days:86400' \
                                'hour/hours:3600' \
                                'minute/minutes:60' \
                                'second/seconds:1'}
  local result=""
  local increment

  for increment in $labeled_increments; do
    local labels="${increment%%:*}"
    local increment="${increment##*:}"

    local singular_label="${labels%%/*}"
    local plural_label="${labels##*/}"

    if (( seconds >= increment )); then
      local quantity=$(( seconds / increment ))
      local label
      if (( quantity == 1 )); then
        label="$singular_label"
      else
        label="$plural_label"
      fi
      seconds=$(( seconds - (quantity * increment) ))
      result="${result}, ${quantity} ${label}"
    fi
  done

  if [ -z "$result" ]; then
    result="0 ${plural_label}"
  fi

  printf '%s\n' "${result#*, }"
}


# inserted from bash_profile/functions/bash/source_find.sh

source_find() {
 local search_dir="$1"; shift
  if [ -z "$search_dir" ]; then
    warn 'source_find: requires a search directory argument, cannot continue'
    return 1
  fi
  if [ -z "$*" ]; then
    warn "source_find: requires find arguments (for example: -name '*.py'), " \
      "cannot continue"
    return 1
  fi

  # temp redirecting outputs so i can grep-out some stderr output
  # via https://unix.stackexchange.com/a/3540
  {
    find "$search_dir" -not '(' '(' \
      -name '*.egg' \
      -or -name '*.egg-info' \
      -or -name '*_cache' \
      -or -name '.AppleDouble' \
      -or -name '.DS_Store' \
      -or -name '.Spotlight-V100' \
      -or -name '.Trashes' \
      -or -name '.cache' \
      -or -name '.eggs' \
      -or -name '.git' \
      -or -name '.hypothesis' \
      -or -name '.idea' \
      -or -name '.ipynb_checkpoints' \
      -or -name '.mypy_cache' \
      -or -name '.npm' \
      -or -name '.pybuilder' \
      -or -name '.pytest_cache' \
      -or -name '.sass-cache' \
      -or -name '.sessions' \
      -or -name '.sourcemint' \
      -or -name '.svn' \
      -or -name '.venv' \
      -or -name '.vs' \
      -or -name '.vscode' \
      -or -name '.yarn-integrity' \
      -or -name '__pycache__' \
      -or -name '__pypackages__' \
      -or -name 'build' \
      -or -name 'cache' \
      -or -name 'eggs' \
      -or -name 'env' \
      -or -name 'logs' \
      -or -name 'node_modules' \
      -or -name 'restore' \
      -or -name 'site-packages' \
      -or -name 'vendor' \
      -or -name 'venv' \
      -or -name 'venv.bak' \
      -or -name 'wheels' \
    ')' -prune ')' \
    -type f \
    "$@" \
    2>&1 1>&3 \
    | grep -vF 'Operation not permitted';
  } 3>&1
}


# inserted from bash_profile/functions/bash/tprint.sh

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


# inserted from bash_profile/functions/bash/venv.sh

venv() {
  if type deactivate >/dev/null 2>&1; then
    warn "deactivating current venv"
    deactivate
    return
  fi

  if [ -d 'venv' ]; then
    warn "activating existing venv"
    # shellcheck source=/dev/null
    source venv/bin/activate
    return
  fi

  if ! [ -a 'venv' ]; then
    warn "creating, activating, and updating new venv"
    python3 -m venv ./venv || return 1
    # shellcheck source=/dev/null
    source ./venv/bin/activate || return 1
    pip install --upgrade pip || return 1
    return 0
  fi
}


# inserted from bash_profile/functions/posix/cdwd.sh

cdwd() {
  # cdwd: cd to the current working directory
  # sometimes the rug is pulled out from under us; cdwd gets back there
  if [ -n "$1" ]; then
    cd -- "$1"   2>/dev/null || cdwd "$(dirname "$1")"
  else
    cd -- "$PWD" 2>/dev/null || cdwd "$(dirname "$PWD")"
  fi
  pwd
}


# inserted from bash_profile/functions/posix/chop.sh

chop() {
    # this is a shell function instead of an alias so that $COLUMNS is
    # evaluated at runtime, so a changing window width is supported
    expand | cut -c "1-${COLUMNS}"
}


# inserted from bash_profile/functions/posix/collect.sh

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


# inserted from bash_profile/functions/posix/collectd.sh

collectd() {
  collect "$@" || return 1
  cd -- "$1" || return 1
}


# inserted from bash_profile/functions/posix/composefilegrep.sh

composefilegrep() {
  if [ -z "$*" ]; then
    warn "grep arguments required. cannot continue"
    return 1
  fi
  source_find "." \
    '(' -name "docker-compose.yml" -or -name "docker-compose.*.yml" ')' \
    -print0 \
  | xargs -0 -r grep -E "$@"
}


# inserted from bash_profile/functions/posix/dockerfilegrep.sh

dockerfilegrep() {
  if [ -z "$*" ]; then
    warn "grep arguments required. cannot continue"
    return 1
  fi
  source_find "." \
    -name "Dockerfile" \
    -print0 \
  | xargs -0 -r grep -E "$@"
}


# inserted from bash_profile/functions/posix/punt.sh

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


# inserted from bash_profile/functions/posix/pygrep.sh

pygrep() {
  if [ -z "$*" ]; then
    warn "grep arguments required. cannot continue"
    return 1
  fi
  source_find '.' \
    -name "*.py" \
    -print0 \
  | xargs -0 -r grep -E "$@"
}


# inserted from bash_profile/functions/posix/shgrep.sh

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
    tprint -p standout-white "\w"
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
