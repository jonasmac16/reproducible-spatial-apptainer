#!/usr/bin/env bash
set -euo pipefail

server_user="${RSTUDIO_USER:-$(id -un 2>/dev/null || true)}"
port="${RSTUDIO_PORT:-8787}"
address="${RSTUDIO_ADDRESS:-127.0.0.1}"
project_dir="${RSTUDIO_PROJECT_DIR:-$HOME}"

[[ -n "$server_user" && "$server_user" != root ]] || { echo "ERROR: a non-root RStudio user is required" >&2; exit 84; }
getent passwd "$server_user" >/dev/null || {
  echo "ERROR: RStudio server user is not present in the container: $server_user" >&2
  exit 84
}

case "$port" in ''|*[!0-9]*) echo "ERROR: RSTUDIO_PORT must be numeric" >&2; exit 81;; esac
(( port >= 1 && port <= 65535 )) || { echo "ERROR: RSTUDIO_PORT must be between 1 and 65535" >&2; exit 81; }

case "$address" in
  127.0.0.1|localhost|::1) ;;
  *)
    if [[ "${RSTUDIO_ALLOW_REMOTE:-0}" != 1 ]]; then
      echo "ERROR: refusing unauthenticated RStudio on non-loopback address '$address'." >&2
      exit 82
    fi
    ;;
esac

runtime="${RSTUDIO_RUNTIME_DIR:-/var/run/rstudio-server}"
config="${RSTUDIO_CONFIG_HOME:-$HOME/.config/rstudio}"
data="${RSTUDIO_DATA_HOME:-/var/lib/rstudio-server}"
mkdir -p "$runtime" "$config" "$data" "$runtime/cache" "$runtime/config" "$runtime/tmp" "$runtime/run"
chmod 0700 "$runtime" "$config" "$data"

# If the host has no dotfiles, seed the config once from the SIF defaults.
if [[ -z "$(find "$config" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  cp -a /opt/rstudio/default-config/. "$config/"
fi

export XDG_CACHE_HOME="$runtime/cache"
export XDG_CONFIG_HOME="$runtime/config"
export TMPDIR="$runtime/tmp"
export HOME="${RSTUDIO_HOME:-$HOME}"

cookie_key="${RSTUDIO_COOKIE_KEY:-/var/lib/rstudio-server/secure-cookie-key}"
[[ -s "$cookie_key" ]] || { echo "ERROR: secure-cookie key is missing: $cookie_key" >&2; exit 83; }

[[ -d "$project_dir" ]] && cd "$project_dir"

printf 'RStudio Server %s\n' "$(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || echo unknown)"
printf 'R %s\n' "$(R --version | sed -n '1p')"
printf 'Python %s\n' "$(/opt/project/python/bin/python --version 2>&1)"
printf 'Project %s\n' "$project_dir"
printf 'Open http://%s:%s\n' "$address" "$port"
exec /usr/lib/rstudio-server/bin/rserver \
  --server-user="$server_user" \
  --auth-none=1 \
  --auth-validate-users=0 \
  --server-daemonize=0 \
  --server-pid-file="$runtime/rserver.pid" \
  --server-working-dir="$runtime/run" \
  --server-data-dir="$data" \
  --secure-cookie-key-file="$cookie_key" \
  --www-address="$address" \
  --www-port="$port" \
  --rsession-which-r=/usr/local/bin/R
