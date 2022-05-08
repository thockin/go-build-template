# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DBG_MAKEFILE ?=
ifeq ($(DBG_MAKEFILE),1)
    $(warning ***** starting Makefile for goal(s) "$(MAKECMDGOALS)")
    $(warning ***** $(shell date))
else
    # If we're not debugging the Makefile, don't echo recipes.
    MAKEFLAGS += -s
endif

# We don't need make's built-in rules.
MAKEFLAGS += --no-builtin-rules
# Be pedantic about undefined variables.
MAKEFLAGS += --warn-undefined-variables
.SUFFIXES:

# The binaries to build (just the basenames)
BINS := myapp-1 myapp-2

# The platforms we support.
ALL_PLATFORMS := linux/amd64 linux/arm linux/arm64 linux/ppc64le linux/s390x windows/amd64

# Where to push the docker images.
REGISTRY ?= example.com

# This version-strategy uses git tags to set the version string
VERSION ?= $(shell git describe --tags --always --dirty)
#
# This version-strategy uses a manual value to set the version string
#VERSION ?= 1.2.3

# Which Go modules mode to use ("mod" or "vendor")
MOD ?= mod

# Satisfy --warn-undefined-variables.
GOFLAGS ?=
HTTP_PROXY ?=
HTTPS_PROXY ?=

###
### These variables should not need tweaking.
###

# Used internally.  Users should pass GOOS and/or GOARCH.
OS := $(if $(GOOS),$(GOOS),$(shell go env GOOS))
ARCH := $(if $(GOARCH),$(GOARCH),$(shell go env GOARCH))

BASEIMAGE ?= gcr.io/distroless/static

TAG := $(VERSION)__$(OS)_$(ARCH)

BUILD_IMAGE ?= golang:1.17-alpine

BIN_EXTENSION :=
ifeq ($(OS), windows)
  BIN_EXTENSION := .exe
endif

# It's necessary to set this because some environments don't link sh -> bash.
SHELL := /usr/bin/env bash -o errexit -o pipefail -o nounset

# If you want to build all binaries, see the 'all-build' rule.
# If you want to build all containers, see the 'all-container' rule.
# If you want to build AND push all containers, see the 'all-push' rule.
all: # @HELP builds binaries for one platform ($OS/$ARCH)
all: build

# For the following OS/ARCH expansions, we transform OS/ARCH into OS_ARCH
# because make pattern rules don't match with embedded '/' characters.

build-%:
	$(MAKE) build                         \
	    --no-print-directory              \
	    GOOS=$(firstword $(subst _, ,$*)) \
	    GOARCH=$(lastword $(subst _, ,$*))

container-%:
	$(MAKE) container                     \
	    --no-print-directory              \
	    GOOS=$(firstword $(subst _, ,$*)) \
	    GOARCH=$(lastword $(subst _, ,$*))

push-%:
	$(MAKE) push                          \
	    --no-print-directory              \
	    GOOS=$(firstword $(subst _, ,$*)) \
	    GOARCH=$(lastword $(subst _, ,$*))

all-build: # @HELP builds binaries for all platforms
all-build: $(addprefix build-, $(subst /,_, $(ALL_PLATFORMS)))

all-container: # @HELP builds containers for all platforms
all-container: $(addprefix container-, $(subst /,_, $(ALL_PLATFORMS)))

all-push: # @HELP pushes containers for all platforms to the defined registry
all-push: $(addprefix push-, $(subst /,_, $(ALL_PLATFORMS)))

# The following structure defeats Go's (intentional) behavior to always touch
# result files, even if they have not changed.  This will still run `go` but
# will not trigger further work if nothing has actually changed.
OUTBINS = $(foreach bin,$(BINS),bin/$(OS)_$(ARCH)/$(bin)$(BIN_EXTENSION))

build: $(OUTBINS)
	echo

# Directories that we need created to build/test.
BUILD_DIRS := bin/$(OS)_$(ARCH)                   \
              bin/tools                           \
              .go/bin/$(OS)_$(ARCH)               \
              .go/bin/$(OS)_$(ARCH)/$(OS)_$(ARCH) \
              .go/cache                           \
              .go/pkg

# Each outbin target is just a facade for the respective stampfile target.
# This `eval` establishes the dependencies for each.
$(foreach outbin,$(OUTBINS),$(eval  \
    $(outbin): .go/$(outbin).stamp  \
))
# This is the target definition for all outbins.
$(OUTBINS):
	true

# Each stampfile target can reference an $(OUTBIN) variable.
$(foreach outbin,$(OUTBINS),$(eval $(strip   \
    .go/$(outbin).stamp: OUTBIN = $(outbin)  \
)))
# This is the target definition for all stampfiles.
# This will build the binary under ./.go and update the real binary iff needed.
STAMPS = $(foreach outbin,$(OUTBINS),.go/$(outbin).stamp)
.PHONY: $(STAMPS)
$(STAMPS): go-build
	echo -ne "binary: $(OUTBIN)  "
	if ! cmp -s .go/$(OUTBIN) $(OUTBIN); then  \
	    mv .go/$(OUTBIN) $(OUTBIN);            \
	    date >$@;                              \
	    echo;                                  \
	else                                       \
	    echo "(cached)";                       \
	fi

# This runs the actual `go build` which updates all binaries.
go-build: | $(BUILD_DIRS)
	echo "# building for $(OS)/$(ARCH)"
	docker run                                                  \
	    -i                                                      \
	    --rm                                                    \
	    -u $$(id -u):$$(id -g)                                  \
	    -v $$(pwd):/src                                         \
	    -w /src                                                 \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin                \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin/$(OS)_$(ARCH)  \
	    -v $$(pwd)/.go/cache:/.cache                            \
	    -v $$(pwd)/.go/pkg:/go/pkg                              \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(BUILD_IMAGE)                                          \
	    /bin/sh -c "                                            \
	        ARCH=$(ARCH)                                        \
	        OS=$(OS)                                            \
	        VERSION=$(VERSION)                                  \
	        MOD=$(MOD)                                          \
	        GOFLAGS=$(GOFLAGS)                                  \
	        ./build/build.sh ./...                              \
	    "

# Example: make shell CMD="-c 'date > datefile'"
shell: # @HELP launches a shell in the containerized build environment
shell: | $(BUILD_DIRS)
	echo "# launching a shell in the containerized build environment"
	docker run                                                  \
	    -ti                                                     \
	    --rm                                                    \
	    -u $$(id -u):$$(id -g)                                  \
	    -v $$(pwd):/src                                         \
	    -w /src                                                 \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin                \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin/$(OS)_$(ARCH)  \
	    -v $$(pwd)/.go/cache:/.cache                            \
	    -v $$(pwd)/.go/pkg:/go/pkg                              \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(BUILD_IMAGE)                                          \
	    /bin/sh $(CMD)

LICENSES = .licenses

$(LICENSES): | $(BUILD_DIRS)
	pushd tools >/dev/null;                      \
	  unset GOOS; unset GOARCH;                  \
	  export GOBIN=$$(pwd)/../bin/tools;         \
	  go install github.com/google/go-licenses;  \
	  popd >/dev/null
	rm -rf $(LICENSES)
	./bin/tools/go-licenses save ./... --save_path=$(LICENSES)
	chmod -R a+rx $(LICENSES)

CONTAINER_DOTFILES = $(foreach bin,$(BINS),.container-$(subst /,_,$(REGISTRY)/$(bin))-$(TAG))

# We print the container names here, rather than in CONTAINER_DOTFILES so
# they are always at the end of the output.
container containers: # @HELP builds containers for one platform ($OS/$ARCH)
container containers: $(CONTAINER_DOTFILES)
	for bin in $(BINS); do                           \
	    echo "container: $(REGISTRY)/$$bin:$(TAG)";  \
	done
	echo

# Each container-dotfile target can reference a $(BIN) variable.
# This is done in 2 steps to enable target-specific variables.
$(foreach bin,$(BINS),$(eval $(strip                                 \
    .container-$(subst /,_,$(REGISTRY)/$(bin))-$(TAG): BIN = $(bin)  \
)))
$(foreach bin,$(BINS),$(eval                                         \
    .container-$(subst /,_,$(REGISTRY)/$(bin))-$(TAG): bin/$(OS)_$(ARCH)/$(bin)$(BIN_EXTENSION) $(LICENSES) Dockerfile.in  \
))
# This is the target definition for all container-dotfiles.
# These are used to track build state in hidden files.
$(CONTAINER_DOTFILES):
	echo
	sed                                            \
	    -e 's|{ARG_BIN}|$(BIN)$(BIN_EXTENSION)|g'  \
	    -e 's|{ARG_ARCH}|$(ARCH)|g'                \
	    -e 's|{ARG_OS}|$(OS)|g'                    \
	    -e 's|{ARG_FROM}|$(BASEIMAGE)|g'           \
	    Dockerfile.in > .dockerfile-$(BIN)-$(OS)_$(ARCH)
	docker build                             \
	    --no-cache                           \
	    -t $(REGISTRY)/$(BIN):$(TAG)         \
	    -f .dockerfile-$(BIN)-$(OS)_$(ARCH)  \
	    .
	docker images -q $(REGISTRY)/$(BIN):$(TAG) > $@
	echo

push: # @HELP pushes the container for one platform ($OS/$ARCH) to the defined registry
push: container
	for bin in $(BINS); do                     \
	    docker push $(REGISTRY)/$$bin:$(TAG);  \
	done
	echo

# This depends on github.com/estesp/manifest-tool.
manifest-list: # @HELP builds a manifest list of containers for all platforms
manifest-list: all-push
	pushd tools >/dev/null;                                             \
	  export GOBIN=$$(pwd)/../bin/tools;                                \
	  go install github.com/estesp/manifest-tool/v2/cmd/manifest-tool;  \
	  popd >/dev/null
	for bin in $(BINS); do                                    \
	    platforms=$$(echo $(ALL_PLATFORMS) | sed 's/ /,/g');  \
	    bin/tools/manifest-tool                               \
	        --username=oauth2accesstoken                      \
	        --password=$$(gcloud auth print-access-token)     \
	        push from-args                                    \
	        --platforms "$$platforms"                         \
	        --template $(REGISTRY)/$$bin:$(VERSION)__OS_ARCH  \
	        --target $(REGISTRY)/$$bin:$(VERSION);            \
	done

version: # @HELP outputs the version string
version:
	echo $(VERSION)

test: # @HELP runs tests, as defined in ./build/test.sh
test: | $(BUILD_DIRS)
	docker run                                                  \
	    -i                                                      \
	    --rm                                                    \
	    -u $$(id -u):$$(id -g)                                  \
	    -v $$(pwd):/src                                         \
	    -w /src                                                 \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin                \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin/$(OS)_$(ARCH)  \
	    -v $$(pwd)/.go/cache:/.cache                            \
	    -v $$(pwd)/.go/pkg:/go/pkg                              \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(BUILD_IMAGE)                                          \
	    /bin/sh -c "                                            \
	        ARCH=$(ARCH)                                        \
	        OS=$(OS)                                            \
	        VERSION=$(VERSION)                                  \
	        MOD=$(MOD)                                          \
	        GOFLAGS=$(GOFLAGS)                                  \
	        ./build/test.sh ./...                               \
	    "

lint: # @HELP runs golangci-lint
lint: | $(BUILD_DIRS)
	docker run                                                  \
	    -i                                                      \
	    --rm                                                    \
	    -u $$(id -u):$$(id -g)                                  \
	    -v $$(pwd):/src                                         \
	    -w /src                                                 \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin                \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin/$(OS)_$(ARCH)  \
	    -v $$(pwd)/.go/cache:/.cache                            \
	    -v $$(pwd)/.go/pkg:/go/pkg                              \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(BUILD_IMAGE)                                          \
	    /bin/sh -c "                                            \
	        ./build/lint.sh ./...                               \
	    "

$(BUILD_DIRS):
	mkdir -p $@

clean: # @HELP removes built binaries and temporary files
clean: container-clean bin-clean

container-clean:
	rm -rf .container-* .dockerfile-* .push-* $(LICENSES)

bin-clean:
	test -d .go && chmod -R u+w .go || true
	rm -rf .go bin

help: # @HELP prints this message
help:
	echo "VARIABLES:"
	echo "  BINS = $(BINS)"
	echo "  OS = $(OS)"
	echo "  ARCH = $(ARCH)"
	echo "  MOD = $(MOD)"
	echo "  GOFLAGS = $(GOFLAGS)"
	echo "  REGISTRY = $(REGISTRY)"
	echo
	echo "TARGETS:"
	grep -E '^.*: *# *@HELP' $(MAKEFILE_LIST)     \
	    | awk '                                   \
	        BEGIN {FS = ": *# *@HELP"};           \
	        { printf "  %-30s %s\n", $$1, $$2 };  \
	    '
