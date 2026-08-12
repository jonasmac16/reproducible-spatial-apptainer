#!/usr/bin/env bash
set -euo pipefail

source /opt/rstudio/module.env

: "${RSTUDIO_SERVER_VERSION:?RSTUDIO_SERVER_VERSION is required}"
: "${RSTUDIO_SERVER_SHA256:?RSTUDIO_SERVER_SHA256 is required}"

deb="${TMPDIR:-/var/tmp}/rstudio-server-${RSTUDIO_SERVER_VERSION}-amd64.deb"
url="https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_SERVER_VERSION}-amd64.deb"

printf 'Installing RStudio Server %s\n' "$RSTUDIO_SERVER_VERSION"
curl -fL --retry 5 --retry-delay 2 --retry-all-errors "$url" -o "$deb"
printf '%s  %s\n' "$RSTUDIO_SERVER_SHA256" "$deb" | sha256sum -c -

policy=/usr/sbin/policy-rc.d
backup=""
if [[ -e "$policy" ]]; then
  backup="${TMPDIR:-/var/tmp}/policy-rc.d.backup"
  cp -a "$policy" "$backup"
fi
restore_policy() {
  if [[ -n "$backup" && -e "$backup" ]]; then
    cp -a "$backup" "$policy"
    rm -f "$backup"
  else
    rm -f "$policy"
  fi
}
trap restore_policy EXIT
printf '#!/bin/sh\nexit 101\n' > "$policy"
chmod 0755 "$policy"
export SYSTEMD_OFFLINE=1

apt-get install -y --no-install-recommends "$deb"
restore_policy
trap - EXIT
rm -f "$deb"

# Do not bake user/session keys into an immutable SIF. The launcher creates
# user-owned runtime state instead.
rm -f \
  /etc/rstudio/session-rpc-key \
  /etc/rstudio/secure-cookie-key \
  /var/lib/rstudio-server/session-rpc-key \
  /var/lib/rstudio-server/secure-cookie-key

install -d -m 0755 /opt/rstudio/default-config
cp -a /opt/rstudio-defaults/. /opt/rstudio/default-config/

/usr/lib/rstudio-server/bin/rserver --check-config
