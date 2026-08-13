# Base scientific R selection. Exact versions are captured in renv.lock.
project_r_packages <- c(
  "BiocVersion",
  "Rcpp",
  "data.table",
  "dplyr",
  "tidyr",
  "purrr",
  "ggplot2",
  "patchwork",
  "reticulate"
)

# Exact Git sources can be added as entries with package, url and immutable ref.
project_r_git_remotes <- list()
