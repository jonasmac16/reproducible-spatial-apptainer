# Reproducible Spatial Transcriptomics Apptainer Environment

A single-repository, publication-oriented Apptainer environment for spatial transcriptomics using R and Python. The final `.sif` contains the complete runtime: R, Python, compilers/native libraries, Quarto, **RStudio Server**, and the project-specific package environments restored from `renv.lock` and `uv.lock`.

## Design principles

- The final SIF is built **directly from a pinned OCI base**. There is no `Bootstrap: localimage` chain.
- Project R/Python packages are installed **inside the SIF**, never into host user space.
- R restores prefer frozen Posit Package Manager Linux binaries for Ubuntu Noble/R 4.6; source compilation remains a controlled fallback for packages without compatible binaries.
- Python uses `uv.lock` with wheel-first installation.
- RStudio Server is part of the same SIF and uses the exact container R/Python runtime.
- Personal RStudio configuration stays on the host and is optionally bind-mounted; conservative defaults are shipped in the SIF as a fallback.
- The published SIF + SHA256 is the primary manuscript reproducibility artifact; the definition and lockfiles are the reconstruction/audit path.

## Repository layout

```text
.
├── container/
│   ├── environment.def.in   # rendered for each profile/build mode
│   ├── rstudio/
│   │   ├── validate.sh
│   │   ├── start-server.sh
│   │   ├── module.env
│   │   ├── defaults/
│   │   ├── themes/
│   │   ├── keybindings/
│   │   ├── snippets/
│   │   └── templates/
│   └── scripts/
├── env/
│   ├── PROFILE
│   ├── R/
│   │   └── package_set.R
│   └── python/
│       └── pyproject.toml
├── profiles/
│   ├── base/
│   └── spatial/
├── scripts/
├── tests/
├── release/
├── versions.env
└── Makefile
```

## Build

The current host setup you have been using is supported directly:

```bash
make lock BUILD_AS_ROOT=1
make build BUILD_AS_ROOT=1
make test
```

For a host with working rootless fakeroot:

```bash
make lock
make build
make test
```

If Apptainer is not in `sudo`'s PATH:

```bash
make lock BUILD_AS_ROOT=1 APPTAINER=/absolute/path/to/apptainer
```

`BUILD_AS_ROOT=1` is only for image construction. Runtime does not require root.

## Profiles

```bash
make profile PROFILE=base
make profile PROFILE=spatial
```

Each profile is maintained on a Git branch with the same name. Selecting a
profile switches to that branch, creates it from the current branch when it
does not exist, and preserves that branch's lockfiles. Profile switching is
refused when the worktree has uncommitted changes. A newly created branch has
its active manifests initialized and is ready for lock resolution; commit the
manifests and generated locks on that profile branch.

`base` is a compact scientific/interoperability environment. `spatial` is the complete spatial-transcriptomics stack developed for this project.

The current spatial profile includes Scanpy, Squidpy, SpatialData, Sopa, scvi-tools, cell2location, CellTypist, Scrublet, LIANA, decoupler, PyDESeq2, scIB metrics, imaging/geospatial tools, and the corresponding R spatial/QC/deconvolution stack.

## Lock lifecycle

First resolution on a profile branch:

```bash
make profile PROFILE=spatial
make lock BUILD_AS_ROOT=1
```

This creates temporary resolver state from the **same pinned OCI base** and extracts:

```text
env/python/uv.lock
env/R/renv.lock
```

Commit those files on the profile branch. They are then the authoritative
dependency specifications for that profile. The general `main` branch does
not carry profile-specific lockfiles.

Final image:

```bash
make build BUILD_AS_ROOT=1
```

The final SIF contains the complete project R and Python environments. No host `.venv` or `renv/library` is required.

## R binary acceleration

The R configuration uses a single frozen Posit Public Package Manager snapshot from `versions.env`. CRAN and Bioconductor repositories are derived from that snapshot. Compatible Linux binaries are preferred by `renv`; packages with no compatible binary, including pinned Git packages such as STdeconvolve, may compile from source.

The snapshot is intentionally not `latest`. Update it deliberately before regenerating `renv.lock`.

## Profiles and Build Modes

The repository is a general-purpose environment builder. Profiles provide the
readable package manifests and can be expanded without changing the builder.
The included profiles are:

```bash
make profiles
make profile PROFILE=base
make profile PROFILE=spatial
```

RStudio is included by default. Headless images omit RStudio and are smaller:

```bash
make lock PROFILE=spatial
make build PROFILE=spatial
make build PROFILE=spatial RSTUDIO=0
```

Use matching `RSTUDIO` values for lock resolution and final builds. The lock
resolver and final image always use the same pinned OCI base.

## RStudio Server

RStudio Server is installed **inside the final SIF**. It is maintained under `container/rstudio/` in this same repository rather than in a separate container.

Start it with:

```bash
make rstudio PROJECT=/path/to/project
```

Optionally provide Git-managed host configuration:

```bash
make rstudio \
  PROJECT=/path/to/project \
  RSTUDIO_CONFIG_HOST=$HOME/dotfiles/rstudio
```

Open:

```text
http://127.0.0.1:8787
```

The launcher explicitly binds persistent writable state under
`~/.local/share/reproducible-env/rstudio/`. This is required because an
Apptainer SIF is immutable. `--writable-tmpfs` is only an ephemeral safety
layer and is not used for RStudio's persistent state. The launcher creates a
runtime user overlay for `/etc/passwd` and `/etc/group`, binds a host-owned
home, `/tmp`, `/var/lib/rstudio-server`, and `/var/run/rstudio-server`, and
uses a host-owned secure-cookie key. This follows Rocker's Apptainer pattern
without hardcoding a username.

RStudio sessions use an image-side wrapper that explicitly exports the
container Python environment, `RETICULATE_PYTHON`, and the embedded R library
paths. The project is mounted at `/workspace/project` and used as the RStudio
server working directory.

If the browser reports a redirect loop, stop the server and inspect the paths:

```bash
make rstudio-diagnose
```

To reset only RStudio state, remove
`~/.local/share/reproducible-env/rstudio/` and start it again. This removes
the host-backed work directory used by the previous launch.

The launcher runs RStudio sessions as the current host user, dynamically
adding that user to container passwd/group overlays. If a browser retains an
old malformed secure-cookie, clear cookies for `127.0.0.1:8787` once after
changing the runtime configuration.

The launcher refuses non-loopback unauthenticated exposure unless `RSTUDIO_ALLOW_REMOTE=1` is explicitly set. For remote/HPC use, prefer SSH port forwarding.

## Runtime analysis

```bash
IMAGE=dist/environment.sif \
PROJECT=$PWD \
DATA=$PWD/data \
RESULTS=$PWD/results \
./scripts/run-analysis.sh Rscript scripts/analysis.R
```

For NVIDIA GPUs:

```bash
GPU=1 IMAGE=dist/environment.sif \
./scripts/run-analysis.sh python scripts/model.py
```

Apptainer provides the host NVIDIA driver interface with `--nv`; the image contains user-space CUDA dependencies only.

## Publication

At manuscript freeze:

```bash
make test
make provenance
make release RELEASE_VERSION=manuscript-v1
```

The release contains the SIF, its SHA256, lockfile/source hashes, and provenance metadata. The SIF can also be pushed to an ORAS-compatible registry.

Readers should normally **download the published SIF** rather than rebuild it. The image checksum is the authoritative identity of the environment. The definition, `renv.lock`, `uv.lock`, and `versions.env` remain available for audit or reconstruction.

## Reproducibility manifest

| Component | Pin |
|---|---|
| Base OCI | `ghcr.io/rocker-org/r-ver@sha256:8c6bcd19...826e108` |
| OS family | Ubuntu Noble inherited from Rocker |
| Architecture | amd64/x86-64 |
| R | 4.6.1 |
| Bioconductor | 3.23 |
| Python | 3.13.15 |
| uv | 0.12.3 |
| renv | 1.2.3 |
| Quarto | 1.9.38 |
| RStudio Server | supplied by pinned `rocker/rstudio:4.6.1` base in interactive mode |
| R package repository | frozen PPM snapshot in `versions.env` |
| R lock | `env/R/renv.lock` |
| Python lock | `env/python/uv.lock` |
| GPU | optional, host driver via `apptainer exec --nv` |
| Runtime network | not required |
| Build network | required for first resolution/build |
| Primary publication artifact | SIF + SHA256 |

## Known limitation

The archived SIF is the strongest reproducibility artifact. A future rebuild may not be byte-identical because Ubuntu system-package repositories remain externally mutable even though the OCI base, language versions, package locks, direct binary checksums, Git SHAs, and major release artifacts are pinned.
