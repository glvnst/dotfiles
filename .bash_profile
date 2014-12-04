#!/bin/bash


#
# Basic settings
#
PS1_TEMPLATE="\D{%j %H:%M:%S} \u<b>@</b>\h<b>:</b>\w <b>\$</b> "
LOCAL_SETTINGS_FILES=("$HOME/.profile_local" "$HOME/.bash_local")
PATH_ITEMS=(
    "$HOME/bin"
    "/bin"
    "/usr/bin"
    "/usr/share/bin"
    "/usr/local/bin"
    "/usr/contrib/bin"
    "/usr/X11R6/bin"

    "/sbin"
    "/usr/sbin"
    "/usr/share/sbin"
    "/usr/local/sbin"
    "/usr/contrib/sbin"
    "/usr/X11R6/sbin"

    "/usr/libexec"
    "/usr/local/libexec"
)


#
# Some plumbing
#
is_function() {
   test "$(type -t $@)" == "function"
}

path_setup() {
    local -a output_dirs;
    local dir;

    for dir in "$@"; do
        if [[ -n "${dir}" && -d "${dir}" ]]; then
            output_dirs+=("$dir")
        fi
    done

    local IFS=":"
    echo "${output_dirs[*]}"
}

prog_search() {
    local IFS=":"
    local prog
    local dir

    for prog in "$@"; do
        for dir in $PATH; do
            if [ -x "${dir}/${prog}" ]; then
                echo "${dir}/${prog}"
                break 2
            fi
        done
    done

   return 0
}

build_ps1() 
{ 
   # The template
   local OUT=$PS1_TEMPLATE;

   # Expand <b>bold</b> tags
   OUT=${OUT//<b>/'\[\e[97m\]'};
   OUT=${OUT//<\/b>/'\[\e[39m\]'};

   echo -E "${OUT}"
}

fmt_duration() {
    # takes a number of seconds and prints it in years, hours, minutes, seconds
    # example usage:
    # $ fmt_duration 35000000
    # 1 year, 39 days, 20 hours, 13 minutes, 20 seconds
    #
    # Note: 1 year is treated as 365.25 days to account for "leap years"
    local -r -a labels=('years' 'days' 'hours' 'minutes' 'seconds');
    local -r -a increments=(31557600 86400 3600 60 1);
    local i label increment quantity
    local result=""
    local seconds=${1:-0}

    for ((i=0; i < ${#increments[@]}; i+=1)); do
        increment=${increments[i]}
        label=${labels[i]}

        if [ $seconds -ge $increment ]; then
            quantity=$((seconds / increment))
            if [ $quantity -eq 1 ]; then
                # Strip the "s" off the end for singular increments
                label=${label:0:${#label}-1}
            fi
            seconds=$(( seconds - (quantity * increment) ))
            result="${result} ${quantity} ${label},"
        fi
    done

    if [ ${#result} -eq 0 ]; then
        # "0 seconds" or 0 (whatever the final label is)
        echo "0 ${labels[${#labels[@]} - 1]}"
    else
        # exclude the final extraneous comma
        echo ${result:0:${#result}-1}
    fi
}


#
# Start setting things up
#

# Establish the path environment variable
PATH=$(path_setup "${PATH_ITEMS[@]}")


# Setup the shell window updates
if ! is_function pre_prompt; then
   pre_prompt() {
      # Update terminal window title
      printf '\e]0;%s\a' "${HOME##*/}@${HOSTNAME}: ${PWD}"

      # If a command took more than ten seconds, report the time
      local RUNTIME=$((SECONDS - PRE_EXEC_COMMAND_TIMER))
      if [ $RUNTIME -gt 5 ]; then
         echo "<< completed in $(fmt_duration $RUNTIME) >>"
      fi

      # Enable the pre_exec command
      PRE_EXEC_ENABLE=1
   }
   export -f pre_prompt
fi

if ! is_function pre_exec; then
   pre_exec() {
      # If we aren't "enabled", then we short-circuit
      if test -z "$PRE_EXEC_ENABLE"; then
         return
      fi

      # Update terminal window title
      local last_command=`history 1`
      printf '\e]0;%s\a' "${HOME##*/}@${HOSTNAME}:${PWD} ${last_command#*[[:digit:]] }"

      # Disable the pre_exec function until the next prompt
      # We do this because the debug trap gets caled before
      # the command and after it
      PRE_EXEC_ENABLE=""
      PRE_EXEC_COMMAND_TIMER=$SECONDS
   }
fi

export PRE_EXEC_COMMAND_TIMER=$SECONDS
export PRE_EXEC_ENABLE=""
export PROMPT_COMMAND="pre_prompt"
trap pre_exec DEBUG


#
# User variables
#
export TZ=${TZ:-"US/Pacific"}
export PAGER=$(prog_search less more)
export EDITOR=${EDITOR:-$(prog_search nano vi emacs)}
export FTP_PASSIVE_MODE=${FTP_PASSIVE_MODE:-"1"}
export HISTSIZE=${HISTSIZE:-1500}
export HISTFILESIZE=${HISTFILESIZE:-50}
export HISTTIMEFORMAT=${HISTTIMEFORMAT:-"%j %H:%M:%S: "}
export PS1=$(build_ps1)

#
# User aliases
#
if [ "${PAGER##*/}" = "less" ] ; then
   alias more="less -RiM"
   alias less="less -RiM"
fi
alias ls="ls -F -r -t -h"
alias ll="ls -l -a "
alias lg="ll | grep -i"
alias newer="find . -newerct"
alias unixtime="date '+%s'"
alias unixdate="date '+%s'"
alias dt="pushd ~/Desktop/"
alias dl="pushd ~/Downloads/"
alias jdate="date '+%j %Z'; date -u '+%j %Z'"
alias sdiff='diff --side-by-side -W $COLUMNS'
alias line2null="tr '\n' '\0'" # very useful with xargs -0



#
# Shell options
#
shopt -s checkwinsize # make terminal window size changes work
unset ignoreeof # Control-D to terminate a shell


#
# User functions
#
if ! is_function chop; then
   chop() { 
      # this is a shell function instead of an alias so that $COLUMNS is
      # evaluated at runtime, so a changing window width is supported
      cut -c "1-$COLUMNS"
   }
   export -f chop
fi


if ! is_function loopthat; then
   # this requires the watch program which is standard on ubuntu and available
   # from homebrew
   if type watch &>/dev/null ; then
      loopthat()
      {
         local cmd=`fc -n -l -1`
         local interval

         echo "Command is \"${cmd}\""
         echo -n "How many seconds between iterations? : "
         read -e interval
         watch --interval=${interval} -- $cmd
      }
   fi
fi


COLLECT_LAST=""
collect () 
{ 
    # Check argument count, show help if incorrect
    if ((${#@} < 2)); then
        echo "Usage: collect <directory> <file to mv to directory> ..." 1>&2;
        echo "  * The directory will be created if it doesn't exist." 1>&2;
        return 1;
    fi;

    local directory=$1;
    shift;
    
    # Make the directory if necessary
    if [ '!' -d "$directory" ]; then
        mkdir -p "$directory";
    fi;

    # Do the move
    mv -i -- "$@" "$directory/";
    COLLECT_LAST="$directory";

    return 0
}
export -f collect


collectd () 
{ 
    # Check argument count, show help if incorrect
    if ((${#@} < 2)); then
        echo "Usage: collect <directory> <file to mv to directory> ..." 1>&2;
        echo "  * The directory will be created if it doesn't exist." 1>&2;
        echo "  * After the mv, 'pushd <directory>' will be called." 1>&2;
        return 1;
    fi;

    # collect, then cd to created directory
    collect "$@";
    pushd "$COLLECT_LAST";

    return 0
}
export -f collectd


export CONC_MAX=2
conc () 
{ 
    local -a procs=($(jobs -p));
    local proc_count=${#procs[@]};

    # Block until there is an open slot
    if ((proc_count >= CONC_MAX)); then
        wait;
    fi;

    # Start our task
    ( "$@" ) &
}
export -f conc


xconc () 
{ 
    local command=$1;
    shift;
    local arg_count=${#@};
    local group_size=$(( arg_count / CONC_MAX ));
    local group_count=$(( (arg_count / group_size) + (arg_count % group_size ? 1 : 0) ));
    (
        local i;
        local start;
        for ((i = 0; i < group_count; i++ )); do
            start=$(( (i * group_size) + 1 ));
            conc "$command" "${@:$start:$group_size}";
        done;
        wait
    )
}
export -f xconc


# Source the local settings file
for SETTINGS_FILE in "${LOCAL_SETTINGS_FILES[@]}"; do
  if [[ -a "$SETTINGS_FILE" ]]; then
    source "$SETTINGS_FILE"
  fi
done


#
# Cleanup
#
unset -v PS1_TEMPLATE PATH_ITEMS LOCAL_SETTINGS_FILES SETTINGS_FILE
unset -f is_function path_setup prog_search build_ps1
