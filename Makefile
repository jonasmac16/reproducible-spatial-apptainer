SHELL := /bin/bash
APPTAINER ?= apptainer
BUILD_AS_ROOT ?= 0
BUILD_FLAGS ?=
IMAGE ?= $(CURDIR)/dist/environment.sif
PROJECT ?= $(CURDIR)
RSTUDIO_CONFIG_HOST ?= $(HOME)/.config/rstudio
PROFILE ?= spatial
CMD ?= bash

.PHONY: help profiles profile lock build test provenance rstudio rstudio-diagnose run release fetch clean distclean
help:
	@printf '%s\n' \
	  'make profiles                      # list available environment profiles' \
	  'make profile PROFILE=base|spatial  # select readable package manifests; removes locks' \
	  'make lock PROFILE=spatial          # resolve locks using the selected build mode' \
	  'make lock BUILD_AS_ROOT=1          # build with sudo, no fakeroot flags' \
	  'make build                         # interactive image with RStudio (default)' \
	  'make build RSTUDIO=0               # lightweight headless image' \
	  'make test                          # run image %test again' \
	  'make rstudio PROJECT=/path/to/project [RSTUDIO_CONFIG_HOST=...]' \
	  'make release RELEASE_VERSION=manuscript-v1 [PUBLISH_URI=oras://...]' \
	  'make fetch RELEASE_META=release/image.env' \
	  'make run CMD="Rscript scripts/analysis.R"  # or call scripts/run-analysis.sh directly'

profiles:
	@for profile in profiles/*; do [ -d "$$profile" ] && printf '%s\n' "$${profile#profiles/}"; done

profile:
	./scripts/select-profile.sh '$(PROFILE)'

lock:
	APPTAINER='$(APPTAINER)' BUILD_AS_ROOT='$(BUILD_AS_ROOT)' BUILD_FLAGS='$(BUILD_FLAGS)' PROFILE='$(PROFILE)' RSTUDIO='$(RSTUDIO)' ./scripts/resolve-locks.sh

build:
	APPTAINER='$(APPTAINER)' BUILD_AS_ROOT='$(BUILD_AS_ROOT)' BUILD_FLAGS='$(BUILD_FLAGS)' IMAGE='$(IMAGE)' PROFILE='$(PROFILE)' RSTUDIO='$(RSTUDIO)' ./scripts/build.sh

test:
	$(APPTAINER) test '$(IMAGE)'

provenance:
	$(APPTAINER) exec '$(IMAGE)' environment-provenance

rstudio:
	SIF='$(IMAGE)' PROJECT='$(abspath $(PROJECT))' RSTUDIO_CONFIG_HOST='$(RSTUDIO_CONFIG_HOST)' APPTAINER='$(APPTAINER)' ./container/rstudio/host/start-rstudio.sh

rstudio-diagnose:
	SIF='$(IMAGE)' ./container/rstudio/host/diagnose-rstudio.sh

release:
	APPTAINER='$(APPTAINER)' IMAGE='$(IMAGE)' RELEASE_VERSION='$(RELEASE_VERSION)' PROJECT_NAME='$(PROJECT_NAME)' PUBLISH_URI='$(PUBLISH_URI)' PROFILE='$(PROFILE)' RSTUDIO='$(RSTUDIO)' ./scripts/release.sh

fetch:
	APPTAINER='$(APPTAINER)' RELEASE_META='$(RELEASE_META)' ./scripts/fetch-image.sh

run:
	APPTAINER='$(APPTAINER)' IMAGE='$(IMAGE)' ./scripts/run-analysis.sh $(CMD)

clean:
	rm -rf .build/*

distclean: clean
	rm -f env/python/uv.lock env/R/renv.lock dist/*.sif dist/*.sha256
