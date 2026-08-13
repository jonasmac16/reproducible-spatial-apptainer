#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"
# shellcheck source=scripts/lib-build.sh
source "$root/scripts/lib-build.sh"

APPTAINER="${APPTAINER:-apptainer}"
IMAGE="${IMAGE:-$root/dist/environment.sif}"
PROFILE="${PROFILE:-$(git branch --show-current)}"
[[ -n "$PROFILE" ]] || { echo "ERROR: cannot determine the current profile branch." >&2; exit 4; }
RSTUDIO="${RSTUDIO:-1}"
current_branch="$(git branch --show-current)"
[[ "$current_branch" == "$PROFILE" ]] || {
  echo "Current branch is '$current_branch', requested profile '$PROFILE'; run 'make profile PROFILE=$PROFILE' first." >&2
  exit 4
}
active_profile="$(tr -d '\n' < "$root/env/PROFILE" 2>/dev/null || true)"
[[ "$active_profile" == "$PROFILE" ]] || {
  echo "Active profile is '$active_profile', requested '$PROFILE'; run 'make lock PROFILE=$PROFILE' first." >&2
  exit 4
}
test -s "$root/env/python/uv.lock" || { echo "Missing env/python/uv.lock; run 'make lock'" >&2; exit 3; }
test -s "$root/env/R/renv.lock" || { echo "Missing env/R/renv.lock; run 'make lock'" >&2; exit 3; }

apptainer_bin="$(resolve_apptainer_binary)"
make_apptainer_build_command "$apptainer_bin"
make_apptainer_build_flags
definition="$($root/scripts/render-definition.sh)"

mkdir -p "$(dirname "$IMAGE")"
rm -f "$IMAGE"
printf 'Building final image with:' >&2
printf ' %q' "${APPTAINER_BUILD_CMD[@]}" "build" "${APPTAINER_BUILD_FLAGS[@]}" >&2
printf ' %q %q\n' "$IMAGE" "$definition" >&2
"${APPTAINER_BUILD_CMD[@]}" build "${APPTAINER_BUILD_FLAGS[@]}" "$IMAGE" "$definition"
sha256sum "$IMAGE" > "$IMAGE.sha256"
echo "Built: $IMAGE"
cat "$IMAGE.sha256"
