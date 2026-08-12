#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1]] else "locked"
lib <- "/opt/project/R/library"
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, "/opt/R/tooling", .libPaths()))

snapshot <- Sys.getenv("R_PPM_SNAPSHOT")
cran_repo <- Sys.getenv("R_PPM_CRAN_URL")
bioc_mirror <- Sys.getenv("R_PPM_BIOC_MIRROR")
bioc_version <- Sys.getenv("BIOCONDUCTOR_VERSION")

stopifnot(nzchar(snapshot), nzchar(cran_repo), nzchar(bioc_mirror), nzchar(bioc_version))

# Posit Package Manager Linux binaries are selected using the distribution-specific
# repository URL and R's platform user-agent. renv keeps exact package versions from
# renv.lock while using this frozen repository as the download source.
r_user_agent <- paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
options(
  repos = c(CRAN = cran_repo),
  BioC_mirror = bioc_mirror,
  download.file.method = "curl",
  download.file.extra = sprintf(
    '--fail --location --retry 5 --header "User-Agent: R (%s)"',
    r_user_agent
  )
)

Sys.setenv(
  RENV_PATHS_CACHE = "/var/tmp/renv-cache-disabled",
  RENV_CONFIG_CACHE_ENABLED = "FALSE",
  RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE",
  RENV_CONFIG_PPM_ENABLED = "TRUE",
  RENV_DOWNLOAD_METHOD = "curl"
)

# Give renv explicit Bioconductor repositories derived from the frozen PPM mirror.
# The software repository can be served as a precompiled Linux binary; annotation,
# experiment-data and workflow repositories are data/source packages by design.
options(
  renv.bioconductor.repos = BiocManager::repositories(version = bioc_version)
)

message("R package repositories:")
message("  CRAN snapshot: ", cran_repo)
message("  Bioconductor mirror: ", bioc_mirror)
message("  Bioconductor release: ", bioc_version)

if (identical(mode, "locked")) {
  renv::restore(
    lockfile = "/opt/project/env/R/renv.lock",
    library = lib,
    repos = getOption("repos"),
    prompt = FALSE,
    clean = TRUE
  )
} else {
  source("/opt/project/env/R/package_set.R", local = TRUE)
  BiocManager::install(
    project_r_packages,
    lib = lib,
    version = bioc_version,
    ask = FALSE,
    update = FALSE
  )
  if (length(project_r_git_remotes)) {
    for (remote in project_r_git_remotes) {
      remotes::install_git(
        remote$url,
        ref = remote$ref,
        lib = lib,
        dependencies = TRUE,
        upgrade = "never",
        quiet = FALSE
      )
    }
  }
  renv::snapshot(
    library = lib,
    lockfile = "/opt/project/env/R/renv.lock",
    type = "all",
    prompt = FALSE,
    force = TRUE
  )
}
