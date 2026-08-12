#!/usr/bin/env bash
set -euo pipefail
APPTAINER="${APPTAINER:-apptainer}"
IMAGE="${IMAGE:-dist/environment.sif}"
PROJECT="${PROJECT:-$PWD}"
DATA="${DATA:-$PROJECT/data}"
RESULTS="${RESULTS:-$PROJECT/results}"
mkdir -p "$RESULTS/provenance"
[[ -f "$IMAGE" ]] || { echo "Image not found: $IMAGE" >&2; exit 8; }
cmd=("$@")
(( ${#cmd[@]} )) || cmd=(bash)
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
log="$RESULTS/provenance/run-$stamp.txt"
commit=unknown
if git -C "$PROJECT" rev-parse HEAD >/dev/null 2>&1; then commit="$(git -C "$PROJECT" rev-parse HEAD)"; fi
{
  printf 'EXECUTION_DATE_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'IMAGE=%s\n' "$(realpath "$IMAGE")"
  printf 'IMAGE_SHA256=%s\n' "$(sha256sum "$IMAGE" | awk '{print $1}')"
  printf 'SOURCE_COMMIT=%s\n' "$commit"
  printf 'COMMAND='; printf '%q ' "${cmd[@]}"; printf '\n'
  printf 'HOST_KERNEL=%s\n' "$(uname -srmo)"
  printf 'APPTAINER=%s\n' "$($APPTAINER version 2>/dev/null || true)"
  if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi -L 2>/dev/null || true; fi
  printf 'NOTE=input dataset identifiers/checksums should be recorded by the analysis workflow\n'
} > "$log"
opts=(--cleanenv --bind "$PROJECT:/workspace/project" --bind "$DATA:/workspace/data:ro" --bind "$RESULTS:/workspace/results" --pwd /workspace/project)
[[ "${GPU:-0}" == 1 ]] && opts+=(--nv)
printf 'Execution provenance: %s\n' "$log"
exec "$APPTAINER" exec "${opts[@]}" "$IMAGE" "${cmd[@]}"
