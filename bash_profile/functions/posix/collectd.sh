#!/bin/sh

collectd() {
  collect "$@" || return 1
  cd -- "$1" || return 1
}
