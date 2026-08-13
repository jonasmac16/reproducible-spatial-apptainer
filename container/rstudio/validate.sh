#!/usr/bin/env bash
set -euo pipefail

if [[ "${RSTUDIO_ENABLED:-1}" != 1 ]]; then
  echo "RStudio validation skipped (headless build)"
  exit 0
fi
rserver=/usr/lib/rstudio-server/bin/rserver
rsession=/usr/lib/rstudio-server/bin/rsession
wrapper=/opt/rstudio/rsession.sh

for exe in "$rserver" "$rsession"; do
  [[ -x "$exe" ]] || { echo "ERROR: missing RStudio executable: $exe" >&2; exit 71; }
  unresolved="$(LD_LIBRARY_PATH=/usr/local/lib/R/lib ldd "$exe" 2>&1 | awk '/=> not found/ {print $1}' | sort -u || true)"
  if [[ -n "$unresolved" ]]; then
    echo "ERROR: unresolved libraries for $exe:" >&2
    printf '  %s\n' $unresolved >&2
    exit 72
  fi
done
[[ -x "$wrapper" ]] || { echo "ERROR: missing RStudio session wrapper: $wrapper" >&2; exit 76; }

actual_pkg="$(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || true)"
[[ -n "$actual_pkg" ]] || {
  echo "ERROR: RStudio Server package is missing" >&2
  exit 73
}
config_output="$($rserver --check-config 2>&1)" || {
  status=$?
  echo "ERROR: rserver --check-config failed with exit status $status" >&2
  printf '%s\n' "$config_output" >&2
  exit 75
}

printf 'RStudio Server OK: %s\n' "$actual_pkg"
