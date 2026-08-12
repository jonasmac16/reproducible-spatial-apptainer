#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '=== build ==='
cat /opt/provenance/build-info.env 2>/dev/null || true
printf '%s\n' '=== toolchain ==='
R --version | sed -n '1p'
/opt/project/python/bin/python --version
uv --version
printf 'Quarto %s\n' "$(quarto --version)"
printf '%s\n' '=== locks ==='
sha256sum /opt/project/env/python/uv.lock /opt/project/env/R/renv.lock
printf '%s\n' '=== image base / repositories ==='
# shellcheck disable=SC1091
source /opt/project/versions.env
printf 'BASE_IMAGE=%s\n' "$BASE_IMAGE"
printf 'BASE_IMAGE_DIGEST=%s\n' "$BASE_IMAGE_DIGEST"
printf 'R_VERSION=%s\n' "$R_VERSION"
printf 'PYTHON_VERSION=%s\n' "$PYTHON_VERSION"
printf 'BIOCONDUCTOR_VERSION=%s\n' "$BIOCONDUCTOR_VERSION"
printf 'R_PPM_SNAPSHOT=%s\n' "$R_PPM_SNAPSHOT"
printf 'R_PPM_CRAN_URL=%s\n' "$R_PPM_CRAN_URL"
printf 'R_PPM_BIOC_MIRROR=%s\n' "$R_PPM_BIOC_MIRROR"
printf 'RSTUDIO_SERVER_VERSION=%s\n' "${RSTUDIO_SERVER_VERSION:-unknown}"
printf 'RSTUDIO_SERVER_INSTALLED=%s\n' "$(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || echo missing)"
