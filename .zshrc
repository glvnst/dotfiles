#!/bin/zsh

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


function path_setup() {
    local -a output_dirs;
    local dir;

    for dir in "${PATH_ITEMS[@]}"; do
        if [[ -n "${dir}" && -d "${dir}" ]]; then
            output_dirs+=("$dir")
        fi
    done

    local IFS=":"
    echo "${output_dirs[*]}"
}

function fmt_duration() {
    # takes a number of seconds and prints it in years, hours, minutes, seconds
    # example usage:
    # $ fmt_duration 35000000
    # 1 year, 39 days, 20 hours, 13 minutes, 20 seconds
    #
    # Note: 1 year is treated as 365.25 days to account for "leap years"
    local -a labels increments
    labels=( 'years' 'days' 'hours' 'minutes' 'seconds' );
    increments=( 31557600 86400 3600 60 1 );
    local i label increment quantity
    local result=""
    local seconds=${1:-0}

    for ((i=1; i <= $#increments; i++)); do
        increment=${increments[i]}
        label=${labels[i]}

        if [[ $seconds -ge $increment ]]; then
            quantity=$((seconds / increment))
            if [[ $quantity -eq 1 ]]; then
                # Strip the "s" off the end for singular increments
                label=${label:0:${#label}-1}
            fi
            seconds=$(( seconds - (quantity * increment) ))
            result="${result} ${quantity} ${label},"
        fi
    done

    if [[ ${#result} -eq 0 ]]; then
        # "0 seconds" or 0 (whatever the final label is)
        echo "0 ${labels[${#labels[@]}]}"
    else
        # exclude the final extraneous comma
        echo ${result:1:${#result}-2}
    fi
}

function is_function() {
    whence "$1" >/dev/null
}

function prog_search() {
    local prog prog_path

    for prog in "$@"; do
        prog_path=$(whence "$prog")
        if [[ -n "$prog_path" ]]; then
            echo $prog_path
            return 0
        fi
    done

    return 1
}


PATH="$(path_setup):$PATH"


# Setup the shell window updates
if ! is_function precmd; then
    function precmd() {
        local RUNTIME

        # Update terminal window title
        printf '\e]0;%s\a' "${HOME##*/}@${HOST}:${PWD}"

        # If a command took more than ten seconds, report the time
        if [[ $PREEXEC_COMMAND_TIMER -gt 0 ]]; then
            RUNTIME=$((SECONDS - PREEXEC_COMMAND_TIMER))
            if [[ $RUNTIME -gt 5 ]]; then
                echo "<< completed in $(fmt_duration $RUNTIME) >>"
            fi

            PREEXEC_COMMAND_TIMER=0
        fi

        return 0
    }
fi

if ! is_function preexec; then
    function preexec() {
        # Update terminal window title
        printf '\e]0;%s\a' "${HOME##*/}@${HOST}:${PWD} $1"
        PREEXEC_COMMAND_TIMER=$SECONDS

        return 0
    }
fi

export PREEXEC_COMMAND_TIMER=0

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
export PS1="%D{%j} %D{%H}%B:%b%D{%M}%B:%b%D{%S} %n%B@%b%m%B:%b%~ %B%#%b "


#
# User aliases
#
if [[ "${PAGER##*/}" == "less" ]] ; then
   alias more="less -RiM"
   alias less="less -RiM"
fi
alias ls="ls -F -r -t -h "
alias ll="ls -l -a "
alias lg="ll | grep -i"
alias newer="find . -newerct"
alias unixtime="date '+%s'"
alias unixdate=unixtime
alias dt="pushd ~/Desktop/"
alias dl="pushd ~/Downloads/"
alias jdate="date '+%j %Z'; date -u '+%j %Z'"
alias sdiff='diff --side-by-side -W $COLUMNS'
alias line2null="tr '\n' '\0'" # very useful with xargs -0
alias readcert="openssl x509 -text -issuer -subject -dates -hash -fingerprint -in"
alias dumpcert=readcert

#
# Shell options
#
setopt autocd
setopt interactivecomments


#
# User functions
#
if ! is_function chop; then
    function chop() {
        # this is a shell function instead of an alias so that $COLUMNS is
        # evaluated at runtime, so a changing window width is supported
        cut -c "1-$COLUMNS"
    }
fi


if ! is_function loopthat; then
    # this requires the watch program which is standard on ubuntu and available
    # from homebrew
    if type watch &>/dev/null ; then
        function loopthat() {
            local -a cmd
            cmd=( "$(fc -n -l -1)" )

            echo "Command is \"${cmd[@]}\""
            echo -n "How many seconds between iterations? : "
            read -r
            watch --interval=${REPLY} -- "${cmd[@]}"
        }
    fi
fi


if ! is_function collect; then
    function collect() {
        # Check argument count, show help if incorrect
        if [[ ${#@} -lt 2 ]]; then
            echo "Usage: collect <directory> <file to mv to directory> ..." >&2;
            echo "  * The directory will be created if it doesn't exist." >&2;
            return 1;
        fi;

        local directory=$1;
        shift;

        # Make the directory if necessary
        if [[ ! -d "$directory" ]]; then
            mkdir -p "$directory";
        fi;

        # Do the move
        mv -i -- "$@" "$directory/";

        return 0
    }
fi


if ! is_function collectd; then
    function collectd() {
        # Check argument count, show help if incorrect
        if [[ ${#@} -lt 2 ]]; then
            echo "Usage: collect <directory> <file to mv to directory> ..." >&2;
            echo "  * The directory will be created if it doesn't exist." >&2;
            echo "  * After the mv, 'pushd <directory>' will be called." >&2;
            return 1;
        fi;

        local directory=$1;
        shift;

        # collect, then cd to created directory
        collect "$directory" "$@";
        pushd "$directory";

        return 0
    }
fi


if ! is_function concblock; then
    export CONC_MAX=${CONC_MAX:-2}
    zmodload zsh/parameter
    zmodload zsh/zselect

    function concblock () {
        CONC_MAX=${CONC_MAX:-2}

        # Block until there is an open slot
        if [[ ${#jobstates} -ge $CONC_MAX ]]; then
            while; do
                zselect -t 20
                if [[ ${#jobstates} -lt $CONC_MAX ]]; then
                    break
                fi
            done
        fi;

        return 0
    }
fi


if ! is_function xconc; then
    export CONC_MAX=${CONC_MAX:-2}

    function xconc() {
        local command_string arg_count group_size group_count
        command_string=$1;
        shift;
        arg_count=${#@}

        if [[ $arg_count -lt $CONC_MAX ]]; then
            group_size=1
            group_count=$arg_count
        else
            group_size=$(( arg_count / CONC_MAX ));
            group_count=$CONC_MAX
        fi

        remainder=$(( arg_count % (group_count * group_size) ))

        (
            local length=$group_size;
            local offset=1;
            local i;
            for (( i=0; i < $group_count; i++ )); do

                if [[ $remainder -gt 0 ]]; then
                    length=$(( group_size + 1 ))
                    remainder=$(( remainder - 1 ))
                else
                    length=$group_size
                fi

                "${=command_string}" "${@:$offset:$length}" &

                offset=$(( offset + length ))

                concblock
            done; wait
        )

        return 0
    }
fi


if ! is_function bpython; then
    bpython() {
        if test -n "$VIRTUAL_ENV"
        then
            PYTHONPATH="$(python -c 'import sys; print ":".join(sys.path)')" \
            command bpython "$@"
        else
            command bpython "$@"
        fi
    }
fi


if ! is_function venv; then
    venv_hook() {
        if declare -f $1 >/dev/null; then
            echo "==> $1"
            $1
        fi
    }

    venv() {
        if [[ -f venv/hooks.sh ]]; then
            echo "Loading venv/hooks.sh"
            source venv/hooks.sh
        fi

        if [[ -z "$VIRTUAL_ENV" ]]; then
            echo "Activating virtualenv"
            venv_hook venv_preactivate_hook
            source venv/bin/activate
            venv_hook venv_activate_hook
        else
            echo "Deactivating virtualenv"
            venv_hook venv_deactivate_hook
            deactivate
            venv_hook venv_postdeactivate_hook
        fi
    }
fi

# Grab the common stuff
if [[ -f ~/.profile_local ]]; then
    source ~/.profile_local
fi

# Grab the shell-specific stuff
if [[ -f ~/.zsh_local ]]; then
    source ~/.zsh_local
fi



#
# Cleanup
#
unset -v PATH_ITEMS
unset -f is_function path_setup prog_search
