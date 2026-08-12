#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd -P)"
APPTAINER="${APPTAINER:-apptainer}"
SIF="${SIF:-$root/dist/environment.sif}"
PROJECT="${PROJECT:-$PWD}"
CONFIG="${RSTUDIO_CONFIG_HOST:-${HOME}/.config/rstudio}"
PORT="${RSTUDIO_PORT:-8787}"
ADDRESS="${RSTUDIO_ADDRESS:-127.0.0.1}"

[[ -f "$SIF" ]] || { echo "ERROR: SIF not found: $SIF" >&2; exit 91; }
command -v "$APPTAINER" >/dev/null 2>&1 || { echo "ERROR: Apptainer not found: $APPTAINER" >&2; exit 92; }
[[ -d "$PROJECT" ]] || { echo "ERROR: project directory not found: $PROJECT" >&2; exit 93; }

case "$ADDRESS" in
  127.0.0.1|localhost|::1) ;;
  *)
    [[ "${RSTUDIO_ALLOW_REMOTE:-0}" == 1 ]] || { echo "ERROR: refusing non-loopback unauthenticated RStudio; use SSH forwarding." >&2; exit 94; }
    ;;
esac

binds=(--bind "$PROJECT:/workspace/project")
if [[ -d "$CONFIG" && -n "$(find "$CONFIG" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  binds+=(--bind "$CONFIG:/mnt/rstudio-config")
  config_target=/mnt/rstudio-config
else
  config_target="${HOME}/.config/rstudio-spatial-container"
  mkdir -p "$config_target"
fi

mkdir -p "${HOME}/.local/share/rstudio-spatial-container"

exec "$APPTAINER" exec --cleanenv \
  --bind "${HOME}:${HOME}" \
  "${binds[@]}" \
  --env "HOME=$HOME" \
  --env "RSTUDIO_PROJECT_DIR=/workspace/project" \
  --env "RSTUDIO_CONFIG_HOME=$config_target" \
  --env "RSTUDIO_DATA_HOME=${HOME}/.local/share/rstudio-spatial-container/data" \
  --env "RSTUDIO_PORT=$PORT" \
  --env "RSTUDIO_ADDRESS=$ADDRESS" \
  --env "RSTUDIO_ALLOW_REMOTE=${RSTUDIO_ALLOW_REMOTE:-0}" \
  "$SIF" /opt/rstudio/start-server.sh
