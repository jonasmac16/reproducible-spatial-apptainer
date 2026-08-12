#!/usr/bin/env bash
set -euo pipefail
source /opt/project/versions.env

r_actual="$(Rscript -e 'cat(as.character(getRversion()))')"
[[ "$r_actual" == "$R_VERSION" ]] || { echo "R mismatch: $r_actual != $R_VERSION" >&2; exit 50; }
py_actual="$(/opt/project/python/bin/python -c 'import platform; print(platform.python_version())')"
[[ "$py_actual" == "$PYTHON_VERSION" ]] || { echo "Python mismatch: $py_actual != $PYTHON_VERSION" >&2; exit 51; }
uv_actual="$(uv --version | awk '{print $2}')"
[[ "$uv_actual" == "$UV_VERSION" ]] || { echo "uv mismatch: $uv_actual != $UV_VERSION" >&2; exit 52; }
[[ "$(quarto --version)" == "$QUARTO_VERSION" ]] || { echo "Quarto mismatch" >&2; exit 53; }

# Lock-aware package-manager validation; avoid duplicating every locked version.
cd /opt/project/env/python
export UV_PROJECT_ENVIRONMENT=/opt/project/python
export UV_CACHE_DIR="/tmp/uv-validate-$(id -u)"
mkdir -p "$UV_CACHE_DIR"
uv lock --check
uv pip check --python /opt/project/python/bin/python

# Native and cross-language smoke tests that have caught real build failures.
R_LIBS_SITE=/opt/project/R/library:/opt/R/tooling:/usr/local/lib/R/library \
  Rscript -e 'library(tcltk); library(reticulate); use_python("/opt/project/python/bin/python", required=TRUE); import("numpy", convert=FALSE)'
RETICULATE_PYTHON=/opt/project/python/bin/python /opt/project/python/bin/python - <<'PY'
from rpy2 import robjects
r_version = str(
    robjects.r('as.character(getRversion())')[0]
)

if r_version != "4.6.1":
    raise RuntimeError(
        f"rpy2 is connected to unexpected R version: {r_version}"
    )

print(f"rpy2 -> R {r_version} OK")
PY

profile="$(cat /opt/project/env/PROFILE 2>/dev/null || echo custom)"
if [[ "$profile" == spatial ]]; then
  /opt/project/python/bin/python - <<'PY'
import scanpy, spatialdata, squidpy, scvi
PY
  R_LIBS_SITE=/opt/project/R/library:/opt/R/tooling:/usr/local/lib/R/library \
    Rscript -e 'library(SpatialExperiment); library(scater); library(Seurat)'
fi

if [[ -x /opt/rstudio/validate.sh ]]; then
  /opt/rstudio/validate.sh
fi

echo "Environment validation OK ($profile)"
