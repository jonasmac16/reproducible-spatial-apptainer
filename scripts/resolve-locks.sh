#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"
# shellcheck source=scripts/lib-build.sh
source "$root/scripts/lib-build.sh"

APPTAINER="${APPTAINER:-apptainer}"
PROFILE="${PROFILE:-spatial}"
RSTUDIO="${RSTUDIO:-1}"
active_profile="$(tr -d '\n' < "$root/env/PROFILE" 2>/dev/null || true)"
if [[ "$active_profile" != "$PROFILE" ]]; then
  "$root/scripts/select-profile.sh" "$PROFILE"
fi
resolver="$root/.build/resolver.sif"
pylock="$root/env/python/uv.lock"
rlock="$root/env/R/renv.lock"
mkdir -p "$root/.build"

apptainer_bin="$(resolve_apptainer_binary)"
make_apptainer_build_command "$apptainer_bin"
make_apptainer_build_flags
definition="$($root/scripts/render-definition.sh)"

pybak=""; rbak=""
[[ -f "$pylock" ]] && { pybak="$root/.build/uv.lock.bak"; cp "$pylock" "$pybak"; }
[[ -f "$rlock" ]] && { rbak="$root/.build/renv.lock.bak"; cp "$rlock" "$rbak"; }
cleanup() {
  status=$?
  rm -f "$resolver" "$root/.build/uv.lock.new" "$root/.build/renv.lock.new"
  if (( status != 0 )); then
    [[ -n "$pybak" && -f "$pybak" ]] && cp "$pybak" "$pylock" || rm -f "$pylock"
    [[ -n "$rbak" && -f "$rbak" ]] && cp "$rbak" "$rlock" || rm -f "$rlock"
  fi
  rm -f "$pybak" "$rbak"
  exit "$status"
}
trap cleanup EXIT
rm -f "$pylock" "$rlock" "$resolver"

printf 'Building lock resolver with:' >&2
printf ' %q' "${APPTAINER_BUILD_CMD[@]}" "build" "${APPTAINER_BUILD_FLAGS[@]}" >&2
printf ' <resolver.sif> %q\n' "$definition" >&2

"${APPTAINER_BUILD_CMD[@]}" build "${APPTAINER_BUILD_FLAGS[@]}" "$resolver" "$definition"
"$apptainer_bin" exec "$resolver" cat /opt/project/env/python/uv.lock > "$root/.build/uv.lock.new"
"$apptainer_bin" exec "$resolver" cat /opt/project/env/R/renv.lock > "$root/.build/renv.lock.new"
test -s "$root/.build/uv.lock.new" && test -s "$root/.build/renv.lock.new"
mv "$root/.build/uv.lock.new" "$pylock"
mv "$root/.build/renv.lock.new" "$rlock"
rm -f "$pybak" "$rbak"
echo "Resolved lockfiles:"
sha256sum "$pylock" "$rlock"
