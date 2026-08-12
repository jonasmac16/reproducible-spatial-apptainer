#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd -P)"
APPTAINER="${APPTAINER:-apptainer}"
SIF="${SIF:-$root/dist/environment.sif}"
PROJECT="${PROJECT:-$PWD}"
CONFIG="${RSTUDIO_CONFIG_HOST:-${HOME}/.config/rstudio}"
PORT="${RSTUDIO_PORT:-8787}"
ADDRESS="${RSTUDIO_ADDRESS:-127.0.0.1}"
STATE_ROOT="${RSTUDIO_STATE_ROOT:-${HOME}/.local/share/reproducible-env/rstudio}"
RSTUDIO_USER="${RSTUDIO_USER:-$(id -un)}"
RSTUDIO_UID="${RSTUDIO_UID:-$(id -u)}"
RSTUDIO_GID="${RSTUDIO_GID:-$(id -g)}"
RSTUDIO_GROUP="${RSTUDIO_GROUP:-$(id -gn)}"

[[ -f "$SIF" ]] || { echo "ERROR: SIF not found: $SIF" >&2; exit 91; }
command -v "$APPTAINER" >/dev/null 2>&1 || { echo "ERROR: Apptainer not found: $APPTAINER" >&2; exit 92; }
[[ -d "$PROJECT" ]] || { echo "ERROR: project directory not found: $PROJECT" >&2; exit 93; }
[[ -n "$RSTUDIO_USER" && "$RSTUDIO_USER" != root ]] || { echo "ERROR: RSTUDIO_USER must be a non-root host username" >&2; exit 95; }

image_passwd="$STATE_ROOT/passwd.image"
image_group="$STATE_ROOT/group.image"
passwd_overlay="$STATE_ROOT/passwd.custom"
group_overlay="$STATE_ROOT/group.custom"

case "$ADDRESS" in
  127.0.0.1|localhost|::1) ;;
  *)
    [[ "${RSTUDIO_ALLOW_REMOTE:-0}" == 1 ]] || { echo "ERROR: refusing non-loopback unauthenticated RStudio; use SSH forwarding." >&2; exit 94; }
    ;;
esac

mkdir -p "$STATE_ROOT"/{var/lib,var/run,tmp,fake_home,runtime,config,data,cache,work}
chmod 700 "$STATE_ROOT" "$STATE_ROOT"/{var,var/lib,var/run,tmp,fake_home,runtime,config,data,cache,work}

"$APPTAINER" exec "$SIF" cat /etc/passwd > "$image_passwd"
"$APPTAINER" exec "$SIF" cat /etc/group > "$image_group"
awk -F: -v user="$RSTUDIO_USER" '$1 != user' "$image_passwd" > "$passwd_overlay"
awk -F: -v group="$RSTUDIO_GROUP" '$1 != group' "$image_group" > "$group_overlay"
printf '%s:x:%s:%s:Apptainer User:/home/%s:/bin/bash\n' \
  "$RSTUDIO_USER" "$RSTUDIO_UID" "$RSTUDIO_GID" "$RSTUDIO_USER" >> "$passwd_overlay"
printf '%s:x:%s:\n' "$RSTUDIO_GROUP" "$RSTUDIO_GID" >> "$group_overlay"
chmod 600 "$passwd_overlay" "$group_overlay"

cookie_key="$STATE_ROOT/var/lib/secure-cookie-key"
if [[ ! -s "$cookie_key" ]]; then
  umask 077
  openssl rand -base64 32 > "$cookie_key"
fi
chmod 600 "$cookie_key"

binds=(
  --bind "$PROJECT:/workspace/project"
  --home "$STATE_ROOT/fake_home:/home/$RSTUDIO_USER"
  --bind "$passwd_overlay:/etc/passwd:ro"
  --bind "$group_overlay:/etc/group:ro"
  --bind "$STATE_ROOT/var/lib:/var/lib/rstudio-server"
  --bind "$STATE_ROOT/var/run:/var/run/rstudio-server"
  --bind "$STATE_ROOT/tmp:/tmp"
  --bind "$STATE_ROOT/runtime:/rstudio-runtime"
  --bind "$STATE_ROOT/config:/rstudio-config"
  --bind "$STATE_ROOT/data:/rstudio-data"
  --bind "$STATE_ROOT/cache:$STATE_ROOT/cache"
)
if [[ -d "$CONFIG" && -n "$(find "$CONFIG" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  binds+=(--bind "$CONFIG:/mnt/rstudio-config")
  config_target=/mnt/rstudio-config
else
  config_target=/rstudio-config
fi

exec "$APPTAINER" exec --cleanenv \
  "${binds[@]}" \
  --workdir "$STATE_ROOT/work" \
  --env "RSTUDIO_PROJECT_DIR=/workspace/project" \
  --env "RSTUDIO_USER=$RSTUDIO_USER" \
  --env "USER=$RSTUDIO_USER" \
  --env "LOGNAME=$RSTUDIO_USER" \
  --env "USERNAME=$RSTUDIO_USER" \
  --env "HOME=/home/$RSTUDIO_USER" \
  --env "RSTUDIO_RUNTIME_DIR=/var/run/rstudio-server" \
  --env "RSTUDIO_CONFIG_HOME=$config_target" \
  --env "RSTUDIO_DATA_HOME=/var/lib/rstudio-server" \
  --env "XDG_CONFIG_HOME=/home/$RSTUDIO_USER/.config" \
  --env "XDG_CACHE_HOME=/rstudio-runtime/cache" \
  --env "TMPDIR=/tmp" \
  --env "RSTUDIO_COOKIE_KEY=/var/lib/rstudio-server/secure-cookie-key" \
  --env "RSTUDIO_PORT=$PORT" \
  --env "RSTUDIO_ADDRESS=$ADDRESS" \
  --env "RSTUDIO_ALLOW_REMOTE=${RSTUDIO_ALLOW_REMOTE:-0}" \
  "$SIF" /opt/rstudio/start-server.sh
