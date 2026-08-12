# Integrated RStudio Server

RStudio Server is part of the final scientific SIF. This directory keeps IDE-specific installation, defaults, and host launching separate from scientific package manifests without requiring a second repository or parent image.

Host RStudio customisation is optional. If `RSTUDIO_CONFIG_HOST` points to a non-empty directory, it is bind-mounted into the container. Otherwise the SIF's conservative defaults under `defaults/` are copied into user-owned state on first launch.
