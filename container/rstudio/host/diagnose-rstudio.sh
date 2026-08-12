#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd -P)"
SIF="${SIF:-$root/dist/environment.sif}"
STATE_ROOT="${RSTUDIO_STATE_ROOT:-${HOME}/.local/share/reproducible-env/rstudio}"

printf 'SIF=%s\n' "$(realpath "$SIF" 2>/dev/null || printf '%s' "$SIF")"
printf 'STATE_ROOT=%s\n' "$STATE_ROOT"
printf 'PORT=%s\n' "${RSTUDIO_PORT:-8787}"
printf 'ADDRESS=%s\n' "${RSTUDIO_ADDRESS:-127.0.0.1}"
for path in "$STATE_ROOT" "$STATE_ROOT/home" "$STATE_ROOT/runtime" "$STATE_ROOT/config" "$STATE_ROOT/data" "$STATE_ROOT/cache" "$STATE_ROOT/tmp"; do
  if [[ -e "$path" ]]; then
    printf 'WRITABLE[%s]=%s\n' "$path" "$(test -w "$path" && printf yes || printf no)"
  else
    printf 'MISSING=%s\n' "$path"
  fi
done
cookie="$STATE_ROOT/runtime/secure-cookie-key"
if [[ -e "$cookie" ]]; then
  printf 'COOKIE_KEY=%s mode=%s\n' "$cookie" "$(stat -c '%a' "$cookie")"
else
  printf 'COOKIE_KEY=%s missing-until-first-start\n' "$cookie"
fi
