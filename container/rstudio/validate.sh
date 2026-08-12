#!/usr/bin/env bash
set -euo pipefail

source /opt/rstudio/module.env
rserver=/usr/lib/rstudio-server/bin/rserver
rsession=/usr/lib/rstudio-server/bin/rsession

for exe in "$rserver" "$rsession"; do
  [[ -x "$exe" ]] || { echo "ERROR: missing RStudio executable: $exe" >&2; exit 71; }
  unresolved="$(LD_LIBRARY_PATH=/usr/local/lib/R/lib ldd "$exe" 2>&1 | awk '/=> not found/ {print $1}' | sort -u || true)"
  if [[ -n "$unresolved" ]]; then
    echo "ERROR: unresolved libraries for $exe:" >&2
    printf '  %s\n' $unresolved >&2
    exit 72
  fi
done

actual_pkg="$(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || true)"
expected_plus="${RSTUDIO_SERVER_VERSION/-/+}"
[[ "$actual_pkg" == "$RSTUDIO_SERVER_VERSION" || "$actual_pkg" == "$expected_plus" ]] || {
  echo "ERROR: RStudio Server version mismatch: expected $RSTUDIO_SERVER_VERSION (or Debian $expected_plus), actual ${actual_pkg:-missing}" >&2
  exit 73
}

for key in \
  /etc/rstudio/session-rpc-key \
  /etc/rstudio/secure-cookie-key \
  /var/lib/rstudio-server/session-rpc-key \
  /var/lib/rstudio-server/secure-cookie-key; do
  [[ ! -e "$key" ]] || { echo "ERROR: RStudio system key must not be baked into the SIF: $key" >&2; exit 74; }
done

config_output="$($rserver --check-config 2>&1)" || {
  status=$?
  echo "ERROR: rserver --check-config failed with exit status $status" >&2
  printf '%s\n' "$config_output" >&2
  exit 75
}

printf 'RStudio Server OK: %s\n' "$actual_pkg"
