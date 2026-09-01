#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd -P)"
# shellcheck source=scripts/image-path.sh
source "$root/scripts/image-path.sh"
PROFILE="${PROFILE:-$(git -C "$root" branch --show-current 2>/dev/null || true)}"
PROFILE="${PROFILE:-spatial}"
SIF="${SIF:-$(default_image_path "$root" "$PROFILE" 1)}"
STATE_ROOT="${RSTUDIO_STATE_ROOT:-${HOME}/.local/share/reproducible-env/rstudio}"
RSTUDIO_USER="${RSTUDIO_USER:-$(id -un)}"

printf 'SIF=%s\n' "$(realpath "$SIF" 2>/dev/null || printf '%s' "$SIF")"
printf 'STATE_ROOT=%s\n' "$STATE_ROOT"
printf 'PORT=%s\n' "${RSTUDIO_PORT:-8787}"
printf 'ADDRESS=%s\n' "${RSTUDIO_ADDRESS:-127.0.0.1}"
printf 'SERVER_USER=%s\n' "$RSTUDIO_USER"
printf 'AUTH_USER=%s\n' "$RSTUDIO_USER"
printf 'UID=%s GID=%s GROUP=%s\n' "$(id -u)" "$(id -g)" "$(id -gn)"
for path in "$STATE_ROOT" "$STATE_ROOT/fake_home" "$STATE_ROOT/runtime" "$STATE_ROOT/config" "$STATE_ROOT/data" "$STATE_ROOT/cache" "$STATE_ROOT/tmp" "$STATE_ROOT/work" "$STATE_ROOT/var/lib" "$STATE_ROOT/var/run"; do
  if [[ -e "$path" ]]; then
    printf 'WRITABLE[%s]=%s\n' "$path" "$(test -w "$path" && printf yes || printf no)"
  else
    printf 'MISSING=%s\n' "$path"
  fi
done
printf 'WORKDIR=%s\n' "$STATE_ROOT/work"
printf 'PASSWD_OVERLAY=%s\n' "$STATE_ROOT/passwd.custom"
printf 'GROUP_OVERLAY=%s\n' "$STATE_ROOT/group.custom"
printf 'COOKIE_KEY=%s\n' "$STATE_ROOT/var/lib/secure-cookie-key"
