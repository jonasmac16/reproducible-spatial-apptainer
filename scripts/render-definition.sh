#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
profile="${PROFILE:-spatial}"
rstudio="${RSTUDIO:-1}"
build_jobs="${BUILD_JOBS:-$(nproc 2>/dev/null || printf 1)}"
template="$root/container/environment.def.in"
output="${1:-$root/.build/environment.def}"
# shellcheck disable=SC1091
source "$root/versions.env"

case "$rstudio" in
  1|true|TRUE|yes|YES) base="$RSTUDIO_BASE_IMAGE"; digest="$RSTUDIO_BASE_DIGEST"; mode=interactive; enabled=1 ;;
  0|false|FALSE|no|NO) base="$HEADLESS_BASE_IMAGE"; digest="$HEADLESS_BASE_DIGEST"; mode=headless; enabled=0 ;;
  *) echo "ERROR: RSTUDIO must be 0 or 1 (got '$rstudio')." >&2; exit 2 ;;
esac

[[ "$build_jobs" =~ ^[1-9][0-9]*$ ]] || {
  echo "ERROR: BUILD_JOBS must be a positive integer (got '$build_jobs')." >&2
  exit 2
}

mkdir -p "$(dirname "$output")"
sed \
  -e "s|@BASE_IMAGE@|$base|g" \
  -e "s|@BASE_DIGEST@|$digest|g" \
  -e "s|@PROFILE@|$profile|g" \
  -e "s|@BUILD_MODE@|$mode|g" \
  -e "s|@RSTUDIO_ENABLED@|$enabled|g" \
  -e "s|@BUILD_JOBS@|$build_jobs|g" \
  "$template" > "$output"
printf '%s\n' "$output"
