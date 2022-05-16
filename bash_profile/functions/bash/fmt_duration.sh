#!/bin/bash

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
