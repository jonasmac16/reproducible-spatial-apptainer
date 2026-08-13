#!/usr/bin/env bash
set -euo pipefail

export PATH=/opt/project/python/bin:/usr/local/bin:$PATH
export VIRTUAL_ENV=/opt/project/python
export RETICULATE_PYTHON=/opt/project/python/bin/python
export R_LIBS_SITE=/opt/project/R/library:/opt/R/tooling:/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library
export PYTHONNOUSERSITE=1
export PYTHONDONTWRITEBYTECODE=1
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

exec /usr/lib/rstudio-server/bin/rsession "$@"
