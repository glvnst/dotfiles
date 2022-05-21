#!/bin/bash

cdto() {
  # cd to the directory containing the given target (resolving symlinks)
  local target=${1?:this command requires a target argument}
  local depth_gauge=${2:-0}
  local parent
  local link_destination
  local depth_limit=20

  if (( depth_gauge > depth_limit )); then
    warn "cdto exceeded recursion depth limit: ${depth_gauge} > ${depth_limit}"
    return 1
  fi

  if [ -L "$target" ]; then
    link_destination=$(readlink "$target")
    if [ -z "$link_destination" ]; then
      warn "cd readlink failed"
      return 2
    fi
    cdto "$link_destination" $(( depth_gauge + 1 ))
    return
  fi

  if ! [ -e "$target" ]; then
    warn "${target} does not seem to exist"
    return 3
  fi

  parent=$(dirname "$target")
  if [ -z "$parent" ]; then
    warn "cd dirname failed"
    return 4
  fi

  pushd "$parent" || return 5
}
