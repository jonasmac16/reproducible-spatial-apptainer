#!/usr/bin/env bash
set -euo pipefail
profile="${1:?usage: select-profile.sh base|spatial}"
root="$(cd "$(dirname "$0")/.." && pwd -P)"
src="$root/profiles/$profile"
[[ -d "$src" ]] || { echo "Unknown profile: $profile" >&2; exit 2; }
rm -f "$root/env/python/uv.lock" "$root/env/R/renv.lock"
cp "$src/python/pyproject.toml" "$root/env/python/pyproject.toml"
cp "$src/R/package_set.R" "$root/env/R/package_set.R"
cp "$src/system-packages.txt" "$root/env/system-packages.txt"
printf '%s\n' "$profile" > "$root/env/PROFILE"
echo "Selected profile '$profile'; lockfiles removed because the manifest changed."
