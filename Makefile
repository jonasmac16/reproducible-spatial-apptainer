SHELL := /bin/bash
APPTAINER ?= apptainer
BUILD_AS_ROOT ?= 0
BUILD_FLAGS ?=
IMAGE ?= $(CURDIR)/dist/environment.sif
PROFILE ?= spatial
CMD ?= bash

.PHONY: help profile lock build test provenance rstudio run release fetch clean distclean
help:
	@printf '%s\n' \
	  'make profile PROFILE=base|spatial  # select readable package manifests; removes locks' \
	  'make lock                          # resolve both lockfiles in a disposable direct-from-OCI SIF' \
	  'make lock BUILD_AS_ROOT=1          # build with sudo, no fakeroot flags' \
	  'make build                         # build final standalone SIF from OCI + committed locks' \
	  'make test                          # run image %test again' \
	  'make rstudio PROJECT=/path/to/project [RSTUDIO_CONFIG_HOST=...]' \
	  'make release RELEASE_VERSION=manuscript-v1 [PUBLISH_URI=oras://...]' \
	  'make fetch RELEASE_META=release/image.env' \
	  'make run CMD="Rscript scripts/analysis.R"  # or call scripts/run-analysis.sh directly'

profile:
	./scripts/select-profile.sh '$(PROFILE)'

lock:
	APPTAINER='$(APPTAINER)' BUILD_AS_ROOT='$(BUILD_AS_ROOT)' BUILD_FLAGS='$(BUILD_FLAGS)' ./scripts/resolve-locks.sh

build:
	APPTAINER='$(APPTAINER)' BUILD_AS_ROOT='$(BUILD_AS_ROOT)' BUILD_FLAGS='$(BUILD_FLAGS)' IMAGE='$(IMAGE)' ./scripts/build.sh

test:
	$(APPTAINER) test '$(IMAGE)'

provenance:
	$(APPTAINER) exec '$(IMAGE)' environment-provenance

rstudio:
	SIF='$(IMAGE)' PROJECT='$${PROJECT:-$$(pwd)}' RSTUDIO_CONFIG_HOST='$(RSTUDIO_CONFIG_HOST)' APPTAINER='$(APPTAINER)' ./container/rstudio/host/start-rstudio.sh

release:
	APPTAINER='$(APPTAINER)' IMAGE='$(IMAGE)' RELEASE_VERSION='$(RELEASE_VERSION)' PROJECT_NAME='$(PROJECT_NAME)' PUBLISH_URI='$(PUBLISH_URI)' ./scripts/release.sh

fetch:
	APPTAINER='$(APPTAINER)' RELEASE_META='$(RELEASE_META)' ./scripts/fetch-image.sh

run:
	APPTAINER='$(APPTAINER)' IMAGE='$(IMAGE)' ./scripts/run-analysis.sh $(CMD)

clean:
	rm -rf .build/*

distclean: clean
	rm -f env/python/uv.lock env/R/renv.lock dist/*.sif dist/*.sha256
