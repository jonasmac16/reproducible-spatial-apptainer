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

[[ -f "$SIF" ]] || { echo "ERROR: SIF not found: $SIF" >&2; exit 91; }
command -v "$APPTAINER" >/dev/null 2>&1 || { echo "ERROR: Apptainer not found: $APPTAINER" >&2; exit 92; }
[[ -d "$PROJECT" ]] || { echo "ERROR: project directory not found: $PROJECT" >&2; exit 93; }

case "$ADDRESS" in
  127.0.0.1|localhost|::1) ;;
  *)
    [[ "${RSTUDIO_ALLOW_REMOTE:-0}" == 1 ]] || { echo "ERROR: refusing non-loopback unauthenticated RStudio; use SSH forwarding." >&2; exit 94; }
    ;;
esac

mkdir -p "$STATE_ROOT"/{home,runtime,config,data,cache,tmp}
chmod 700 "$STATE_ROOT" "$STATE_ROOT"/{home,runtime,config,data,cache,tmp}

binds=(
  --bind "$PROJECT:/workspace/project"
  --bind "$STATE_ROOT/home:$STATE_ROOT/home"
  --bind "$STATE_ROOT/runtime:$STATE_ROOT/runtime"
  --bind "$STATE_ROOT/config:$STATE_ROOT/config"
  --bind "$STATE_ROOT/data:$STATE_ROOT/data"
  --bind "$STATE_ROOT/cache:$STATE_ROOT/cache"
  --bind "$STATE_ROOT/tmp:$STATE_ROOT/tmp"
)
if [[ -d "$CONFIG" && -n "$(find "$CONFIG" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  binds+=(--bind "$CONFIG:/mnt/rstudio-config")
  config_target=/mnt/rstudio-config
else
  config_target="$STATE_ROOT/config"
fi

exec "$APPTAINER" exec --cleanenv \
  "${binds[@]}" \
  --env "RSTUDIO_PROJECT_DIR=/workspace/project" \
  --env "HOME=$STATE_ROOT/home" \
  --env "RSTUDIO_RUNTIME_DIR=$STATE_ROOT/runtime" \
  --env "RSTUDIO_CONFIG_HOME=$config_target" \
  --env "RSTUDIO_DATA_HOME=$STATE_ROOT/data" \
  --env "XDG_CONFIG_HOME=$STATE_ROOT/config" \
  --env "XDG_CACHE_HOME=$STATE_ROOT/cache" \
  --env "TMPDIR=$STATE_ROOT/tmp" \
  --env "RSTUDIO_COOKIE_KEY=$STATE_ROOT/runtime/secure-cookie-key" \
  --env "RSTUDIO_PORT=$PORT" \
  --env "RSTUDIO_ADDRESS=$ADDRESS" \
  --env "RSTUDIO_ALLOW_REMOTE=${RSTUDIO_ALLOW_REMOTE:-0}" \
  --writable-tmpfs \
  "$SIF" /opt/rstudio/start-server.sh
