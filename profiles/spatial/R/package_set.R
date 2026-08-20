# Curated spatial transcriptomics package set.
# The selection is intentionally readable; exact resolved versions belong in renv.lock.
project_r_packages <- c(
  # Core containers / I/O
  "BiocVersion", "SingleCellExperiment", "SpatialExperiment",
  "SpatialFeatureExperiment", "MoleculeExperiment", "TENxIO", "VisiumIO",
  "XeniumIO", "zellkonverter", "alabaster.spatial", "tidySpatialExperiment",

  # QC, contamination and doublets
  "scater", "scran", "scuttle", "scrapper", "SpotSweeper", "SpotClean",
  "scDblFinder", "celda", "DenoIST",

  # Spatial structure, domains and spatially variable genes
  "Banksy", "BayesSpace", "Voyager", "nnSVG", "spatialDE", "spatialLIBD",
  "SpNeigh", "CatsCradle", "spoon", "spqn",

  # Deconvolution / mapping
  "spacexr", "SpatialDecon", "SPOTlight",

  # General single-cell analysis / normalization
  "Seurat", "SeuratObject", "sctransform", "glmGamPoi", "batchelor",

  # Differential expression / multi-sample inference
  "edgeR", "limma", "DESeq2", "muscat", "dreamlet", "DESpace", "MAST",

  # Large-data backends
  "BiocParallel", "DelayedArray", "SparseArray", "HDF5Array", "rhdf5",

  # Visualization / enrichment / reporting
  "ComplexHeatmap", "dittoSeq", "clusterProfiler", "ggplot2", "patchwork",

  # Data manipulation / geospatial
  "data.table", "dplyr", "tidyr", "tidyverse", "purrr", "future", "future.apply", "sf", "terra",

  # R -> Python
  "reticulate"
)

# STdeconvolve is not in the active Bioconductor release. Pin an immutable Git SHA.
project_r_git_remotes <- list(
  list(
    package = "STdeconvolve",
    url = "https://github.com/JEFworks-Lab/STdeconvolve.git",
    ref = "13b1953263a5ce34e2471c4defebedbda44c7d08"
  ),
  list(
    package = "presto",
    url = "https://github.com/immunogenomics/presto.git",
    ref = "a24772a"
  ),
)
