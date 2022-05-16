#!/bin/sh

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
