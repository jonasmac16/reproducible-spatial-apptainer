#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
APPTAINER="${APPTAINER:-apptainer}"
IMAGE="${IMAGE:-$root/dist/environment.sif}"
RELEASE_VERSION="${RELEASE_VERSION:?set RELEASE_VERSION, e.g. manuscript-v1}"
PROJECT_NAME="${PROJECT_NAME:-$(basename "$root")}"
[[ -f "$IMAGE" ]] || { echo "Image not found: $IMAGE" >&2; exit 5; }
outdir="$root/release/$RELEASE_VERSION"
mkdir -p "$outdir"
out="$outdir/${PROJECT_NAME}-${RELEASE_VERSION}.sif"
cp --reflink=auto "$IMAGE" "$out" 2>/dev/null || cp "$IMAGE" "$out"
sha="$(sha256sum "$out" | awk '{print $1}')"
printf '%s  %s\n' "$sha" "$(basename "$out")" > "$out.sha256"
commit=unknown; dirty=unknown
if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit="$(git -C "$root" rev-parse HEAD)"
  [[ -n "$(git -C "$root" status --porcelain)" ]] && dirty=true || dirty=false
fi
cat > "$outdir/manifest.env" <<EOF2
PROJECT_NAME=$PROJECT_NAME
RELEASE_VERSION=$RELEASE_VERSION
IMAGE_FILE=$(basename "$out")
IMAGE_SHA256=$sha
SOURCE_COMMIT=$commit
SOURCE_DIRTY=$dirty
DEFINITION_SHA256=$(sha256sum "$root/container/environment.def" | awk '{print $1}')
VERSIONS_SHA256=$(sha256sum "$root/versions.env" | awk '{print $1}')
PYTHON_LOCK_SHA256=$(sha256sum "$root/env/python/uv.lock" | awk '{print $1}')
R_LOCK_SHA256=$(sha256sum "$root/env/R/renv.lock" | awk '{print $1}')
R_PPM_SNAPSHOT=$(bash -c 'set -a; source "$1"; printf "%s" "$R_PPM_SNAPSHOT"' _ "$root/versions.env")
EOF2
"$APPTAINER" exec "$out" environment-provenance > "$outdir/environment-provenance.txt"
if [[ -n "${PUBLISH_URI:-}" ]]; then
  "$APPTAINER" push "$out" "$PUBLISH_URI"
  printf '%s\n' "$PUBLISH_URI" > "$outdir/oras-uri.txt"
fi
cat > "$outdir/image.env" <<EOF2
IMAGE_FILE=$(basename "$out")
IMAGE_SHA256=$sha
IMAGE_URL=
IMAGE_ORAS=${PUBLISH_URI:-}
EOF2
printf 'Release prepared: %s\nSIF SHA256: %s\n' "$outdir" "$sha"
