#!/usr/bin/env bash
set -euo pipefail
source /opt/project/versions.env

mkdir -p /opt/uv-python /opt/R/tooling /var/tmp/tool-install
arch="$(uname -m)"
[[ "$arch" == x86_64 ]] || { echo "This pinned environment targets amd64/x86_64; got $arch" >&2; exit 20; }
uv_target=x86_64-unknown-linux-gnu

# Immutable-version upstream artifact with upstream SHA256.
uv_url="https://releases.astral.sh/github/uv/releases/download/${UV_VERSION}/uv-${uv_target}.tar.gz"
curl -fsSL --retry 5 "$uv_url" -o /var/tmp/tool-install/uv.tar.gz
printf '%s  %s\n' "$UV_AMD64_SHA256" /var/tmp/tool-install/uv.tar.gz | sha256sum -c -
mkdir -p /var/tmp/tool-install/uv
tar -xzf /var/tmp/tool-install/uv.tar.gz -C /var/tmp/tool-install/uv --strip-components=1
install -m 0755 /var/tmp/tool-install/uv/uv /usr/local/bin/uv
install -m 0755 /var/tmp/tool-install/uv/uvx /usr/local/bin/uvx

export UV_PYTHON_INSTALL_DIR=/opt/uv-python
export UV_PYTHON_BIN_DIR=/usr/local/bin
uv python install "$PYTHON_VERSION"

install_cran_exact() {
  local pkg="$1"
  local ver="$2"
  local out="/var/tmp/tool-install/${pkg}_${ver}.tar.gz"
  local current="https://cran.r-project.org/src/contrib/${pkg}_${ver}.tar.gz"
  local archive="https://cran.r-project.org/src/contrib/Archive/${pkg}/${pkg}_${ver}.tar.gz"
  curl -fsSL "$current" -o "$out" || curl -fsSL "$archive" -o "$out"
  R CMD INSTALL --library=/opt/R/tooling "$out"
}
install_cran_exact renv "$RENV_VERSION"
install_cran_exact remotes "$REMOTES_VERSION"
install_cran_exact BiocManager "$BIOCMANAGER_VERSION"

# Quarto is downloaded as an exact release artifact and checksum-verified.
[[ "$(dpkg --print-architecture)" == amd64 ]] || { echo "Quarto pin is amd64-only" >&2; exit 21; }
qdeb="/var/tmp/tool-install/quarto-${QUARTO_VERSION}.deb"
qurl="https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb"
curl -fsSL --retry 5 "$qurl" -o "$qdeb"
printf '%s  %s\n' "$QUARTO_SHA256" "$qdeb" | sha256sum -c -
apt-get install -y --no-install-recommends "$qdeb"
