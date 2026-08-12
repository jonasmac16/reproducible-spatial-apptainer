#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"
# shellcheck source=scripts/lib-build.sh
source "$root/scripts/lib-build.sh"

APPTAINER="${APPTAINER:-apptainer}"
IMAGE="${IMAGE:-$root/dist/environment.sif}"
test -s "$root/env/python/uv.lock" || { echo "Missing env/python/uv.lock; run 'make lock'" >&2; exit 3; }
test -s "$root/env/R/renv.lock" || { echo "Missing env/R/renv.lock; run 'make lock'" >&2; exit 3; }

apptainer_bin="$(resolve_apptainer_binary)"
make_apptainer_build_command "$apptainer_bin"
make_apptainer_build_flags

mkdir -p "$(dirname "$IMAGE")"
rm -f "$IMAGE"
printf 'Building final image with:' >&2
printf ' %q' "${APPTAINER_BUILD_CMD[@]}" "build" "${APPTAINER_BUILD_FLAGS[@]}" >&2
printf ' %q %q\n' "$IMAGE" "$root/container/environment.def" >&2
"${APPTAINER_BUILD_CMD[@]}" build "${APPTAINER_BUILD_FLAGS[@]}" "$IMAGE" "$root/container/environment.def"
sha256sum "$IMAGE" > "$IMAGE.sha256"
echo "Built: $IMAGE"
cat "$IMAGE.sha256"
