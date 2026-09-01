#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
# shellcheck source=scripts/image-path.sh
source "$root/scripts/image-path.sh"
meta="${RELEASE_META:-${1:-$root/release/image.env}}"
[[ -f "$meta" ]] || { echo "Release metadata not found: $meta" >&2; exit 6; }
# shellcheck disable=SC1090
source "$meta"
: "${IMAGE_SHA256:?IMAGE_SHA256 missing from $meta}"
IMAGE_FILE="${IMAGE_FILE:-environment.sif}"
PROFILE="${PROFILE:-spatial}"
RSTUDIO="${RSTUDIO:-1}"
dest="${IMAGE_DEST:-$(default_image_path "$root" "$PROFILE" "$RSTUDIO")}"
mkdir -p "$(dirname "$dest")"
rm -f "$dest"
if [[ -n "${IMAGE_ORAS:-}" ]]; then
  "${APPTAINER:-apptainer}" pull --force "$dest" "$IMAGE_ORAS"
elif [[ -n "${IMAGE_URL:-}" ]]; then
  curl -fL --retry 5 "$IMAGE_URL" -o "$dest"
else
  echo "Set IMAGE_ORAS or IMAGE_URL in $meta" >&2; exit 7
fi
printf '%s  %s\n' "$IMAGE_SHA256" "$dest" | sha256sum -c -
echo "Verified image: $dest"
