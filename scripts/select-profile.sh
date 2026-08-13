#!/usr/bin/env bash
set -euo pipefail
profile="${1:?usage: select-profile.sh base|spatial}"
root="$(cd "$(dirname "$0")/.." && pwd -P)"
src="$root/profiles/$profile"
[[ -d "$src" ]] || { echo "Unknown profile: $profile" >&2; exit 2; }
cd "$root"

current_branch="$(git branch --show-current)"
[[ -n "$current_branch" ]] || {
  echo "ERROR: profile selection requires an attached Git branch." >&2
  exit 3
}

if [[ "$current_branch" != "$profile" && -n "$(git status --porcelain)" ]]; then
  echo "ERROR: cannot switch profiles with uncommitted changes." >&2
  echo "Commit or stash the changes before selecting '$profile'." >&2
  exit 4
fi

new_branch=0
if [[ "$current_branch" != "$profile" ]]; then
  if git show-ref --verify --quiet "refs/heads/$profile"; then
    git switch "$profile"
  elif git show-ref --verify --quiet "refs/remotes/origin/$profile"; then
    git switch --track -c "$profile" "origin/$profile"
  else
    git switch -c "$profile"
    new_branch=1
  fi
fi

active_profile="$(tr -d '\n' < env/PROFILE 2>/dev/null || true)"
if [[ "$active_profile" != "$profile" ]]; then
  [[ "$new_branch" == 1 ]] || {
    echo "ERROR: branch '$profile' has env/PROFILE='$active_profile'; refusing to overwrite its manifests." >&2
    exit 5
  }
  rm -f env/python/uv.lock env/R/renv.lock
  cp "$src/python/pyproject.toml" env/python/pyproject.toml
  cp "$src/R/package_set.R" env/R/package_set.R
  cp "$src/system-packages.txt" env/system-packages.txt
  printf '%s\n' "$profile" > env/PROFILE
  echo "Created and selected profile branch '$profile'; manifests initialized."
else
  echo "Selected existing profile branch '$profile'; existing lockfiles preserved."
fi
