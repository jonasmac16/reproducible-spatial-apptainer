#!/usr/bin/env bash
set -euo pipefail
source /opt/project/versions.env
cd /opt/project/env/python
export UV_PYTHON_INSTALL_DIR=/opt/uv-python
export UV_PROJECT_ENVIRONMENT=/opt/project/python
export UV_LINK_MODE=copy
export UV_CACHE_DIR="${UV_CACHE_DIR:-/var/tmp/project-build/uv-cache}"
mkdir -p "$UV_CACHE_DIR"

if [[ -s uv.lock ]]; then
  uv sync --frozen --no-dev --python "$PYTHON_VERSION"
else
  rm -f uv.lock
  uv lock --python "$PYTHON_VERSION"
  uv sync --frozen --no-dev --python "$PYTHON_VERSION"
fi
uv pip check --python /opt/project/python/bin/python
