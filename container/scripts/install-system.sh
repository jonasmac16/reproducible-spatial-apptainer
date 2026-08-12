#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl wget git git-lfs openssh-client openssl \
  build-essential gfortran pkg-config cmake ninja-build make \
  locales jq rsync zip unzip less vim-tiny procps psmisc lsof file \
  libtcl8.6 libtk8.6 tcl8.6 tk8.6 tcl8.6-dev tk8.6-dev \
  libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev libssh2-1-dev \
  zlib1g-dev libbz2-dev liblzma-dev libsqlite3-dev libicu-dev \
  libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev \
  libpng-dev libjpeg-dev libtiff-dev libcairo2-dev libmagick++-dev

extra=/opt/project/env/system-packages.txt
if [[ -s "$extra" ]]; then
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' "$extra")
  if (( ${#pkgs[@]} )); then
    apt-get install -y --no-install-recommends "${pkgs[@]}"
  fi
fi

# Rocker installs R under /usr/local/lib/R; register libR for rsession/native tools.
printf '%s\n' '/usr/local/lib/R/lib' > /etc/ld.so.conf.d/rocker-r.conf
ldconfig
