#!/usr/bin/env bash
# Shared helpers for reproducible Apptainer image construction.

resolve_apptainer_binary() {
  local requested="${APPTAINER:-apptainer}"
  local resolved=""

  if [[ "$requested" == */* ]]; then
    resolved="$requested"
  else
    resolved="$(command -v "$requested" 2>/dev/null || true)"
  fi

  if [[ -z "$resolved" || ! -x "$resolved" ]]; then
    echo "ERROR: cannot resolve an executable Apptainer binary from APPTAINER='$requested'." >&2
    echo "Set APPTAINER to an absolute path, e.g. APPTAINER=/path/to/apptainer." >&2
    return 2
  fi

  printf '%s\n' "$resolved"
}

make_apptainer_build_command() {
  local apptainer_bin="$1"
  local build_as_root="${BUILD_AS_ROOT:-0}"

  case "$build_as_root" in
    0|false|FALSE|no|NO)
      APPTAINER_BUILD_CMD=("$apptainer_bin")
      ;;
    1|true|TRUE|yes|YES)
      command -v sudo >/dev/null 2>&1 || {
        echo "ERROR: BUILD_AS_ROOT=1 requested, but sudo is not available." >&2
        return 2
      }
      APPTAINER_BUILD_CMD=(sudo "$apptainer_bin")
      ;;
    *)
      echo "ERROR: BUILD_AS_ROOT must be 0 or 1 (got '$build_as_root')." >&2
      return 2
      ;;
  esac
}

make_apptainer_build_flags() {
  local build_as_root="${BUILD_AS_ROOT:-0}"
  local raw_flags="${BUILD_FLAGS:-}"

  APPTAINER_BUILD_FLAGS=()
  if [[ -n "$raw_flags" ]]; then
    # BUILD_FLAGS is intended for ordinary whitespace-separated Apptainer flags.
    # Do not use it for shell expressions or quoted arguments containing spaces.
    read -r -a APPTAINER_BUILD_FLAGS <<< "$raw_flags"
  elif [[ "$build_as_root" =~ ^(1|true|TRUE|yes|YES)$ ]]; then
    APPTAINER_BUILD_FLAGS=()
  else
    APPTAINER_BUILD_FLAGS=(--fakeroot)
  fi
}
