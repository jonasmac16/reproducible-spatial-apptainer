#!/usr/bin/env bash

image_mode() {
  case "${1:-1}" in
    1|true|TRUE|yes|YES) printf '%s\n' interactive ;;
    0|false|FALSE|no|NO) printf '%s\n' headless ;;
    *) echo "ERROR: RSTUDIO must be 0 or 1 (got '$1')." >&2; return 2 ;;
  esac
}

default_image_path() {
  local root="$1"
  local profile="$2"
  local rstudio="${3:-1}"
  local mode
  mode="$(image_mode "$rstudio")" || return
  printf '%s\n' "$root/dist/$profile/environment-$mode.sif"
}
