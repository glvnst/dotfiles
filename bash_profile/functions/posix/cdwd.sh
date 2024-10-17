#!/bin/sh

cdwd() {
  # cdwd: cd to the current working directory
  # sometimes the rug is pulled out from under us; cdwd gets back there
  cdwd_dir="${1:-$PWD}"
  while ! cd -- "$cdwd_dir" 2>/dev/null; do
    cdwd_dir=$(dirname "$cdwd_dir")
  done
  pwd
}