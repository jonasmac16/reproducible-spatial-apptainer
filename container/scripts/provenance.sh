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
printf 'BASE_IMAGE=%s\n' "${BASE_IMAGE:-unknown}"
printf 'BASE_IMAGE_DIGEST=%s\n' "${BASE_IMAGE_DIGEST:-unknown}"
printf 'HEADLESS_BASE_IMAGE=%s\n' "${HEADLESS_BASE_IMAGE:-unknown}"
printf 'RSTUDIO_BASE_IMAGE=%s\n' "${RSTUDIO_BASE_IMAGE:-unknown}"
if [[ "${RSTUDIO_ENABLED:-0}" == 1 ]]; then
  printf 'SELECTED_BASE_IMAGE=%s\n' "${RSTUDIO_BASE_IMAGE:-unknown}"
  printf 'SELECTED_BASE_DIGEST=%s\n' "${RSTUDIO_BASE_DIGEST:-unknown}"
else
  printf 'SELECTED_BASE_IMAGE=%s\n' "${HEADLESS_BASE_IMAGE:-unknown}"
  printf 'SELECTED_BASE_DIGEST=%s\n' "${HEADLESS_BASE_DIGEST:-unknown}"
fi
printf 'BUILD_MODE=%s\n' "$(grep '^BUILD_MODE=' /opt/provenance/build-info.env 2>/dev/null | cut -d= -f2- || echo unknown)"
printf 'RSTUDIO_ENABLED=%s\n' "$(grep '^RSTUDIO_ENABLED=' /opt/provenance/build-info.env 2>/dev/null | cut -d= -f2- || echo unknown)"
printf 'R_VERSION=%s\n' "$R_VERSION"
printf 'PYTHON_VERSION=%s\n' "$PYTHON_VERSION"
printf 'BIOCONDUCTOR_VERSION=%s\n' "$BIOCONDUCTOR_VERSION"
printf 'R_PPM_SNAPSHOT=%s\n' "$R_PPM_SNAPSHOT"
printf 'R_PPM_CRAN_URL=%s\n' "$R_PPM_CRAN_URL"
printf 'R_PPM_BIOC_MIRROR=%s\n' "$R_PPM_BIOC_MIRROR"
printf 'RSTUDIO_SERVER_VERSION=%s\n' "$(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || echo not-installed)"
printf 'RSTUDIO_SERVER_INSTALLED=%s\n' "$(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || echo missing)"
