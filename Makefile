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

# The binary to build (just the basename).
BIN := myapp

# This repo's root import path (under GOPATH).
PKG := github.com/thockin/go-build-template

# Where to push the docker image.
REGISTRY ?= thockin

# Which architecture to build - see $(ALL_ARCH) for options.
ARCH ?= amd64

# This version-strategy uses git tags to set the version string
VERSION := $(shell git describe --tags --always --dirty)
#
# This version-strategy uses a manual value to set the version string
#VERSION := 1.2.3

###
### These variables should not need tweaking.
###

SRC_DIRS := cmd pkg # directories which hold app source (not vendored)

ALL_ARCH := amd64 arm arm64 ppc64le

# Set default base image dynamically for each arch
ifeq ($(ARCH),amd64)
    BASEIMAGE?=alpine
endif
ifeq ($(ARCH),arm)
    BASEIMAGE?=armel/busybox
endif
ifeq ($(ARCH),arm64)
    BASEIMAGE?=aarch64/busybox
endif
ifeq ($(ARCH),ppc64le)
    BASEIMAGE?=ppc64le/busybox
endif

IMAGE := $(REGISTRY)/$(BIN)-$(ARCH)

BUILD_IMAGE ?= golang:1.9-alpine

# If you want to build all binaries, see the 'all-build' rule.
# If you want to build all containers, see the 'all-container' rule.
# If you want to build AND push all containers, see the 'all-push' rule.
all: build

build-%:
	@$(MAKE) --no-print-directory ARCH=$* build

container-%:
	@$(MAKE) --no-print-directory ARCH=$* container

push-%:
	@$(MAKE) --no-print-directory ARCH=$* push

all-build: $(addprefix build-, $(ALL_ARCH))

all-container: $(addprefix container-, $(ALL_ARCH))

all-push: $(addprefix push-, $(ALL_ARCH))

build: bin/$(ARCH)/$(BIN)

bin/$(ARCH)/$(BIN): build-dirs
	@echo "building: $@"
	@docker run                                                             \
	    -ti                                                                 \
	    --rm                                                                \
	    -u $$(id -u):$$(id -g)                                              \
	    -v "$$(pwd)/.go:/go"                                                \
	    -v "$$(pwd):/go/src/$(PKG)"                                         \
	    -v "$$(pwd)/bin/$(ARCH):/go/bin"                                    \
	    -v "$$(pwd)/bin/$(ARCH):/go/bin/$$(go env GOOS)_$(ARCH)"            \
	    -v "$$(pwd)/.go/std/$(ARCH):/usr/local/go/pkg/linux_$(ARCH)_static" \
	    -w /go/src/$(PKG)                                                   \
	    $(BUILD_IMAGE)                                                      \
	    /bin/sh -c "                                                        \
	        ARCH=$(ARCH)                                                    \
	        VERSION=$(VERSION)                                              \
	        PKG=$(PKG)                                                      \
	        ./build/build.sh                                                \
	    "

# Example: make shell CMD="-c 'date > datefile'"
shell: build-dirs
	@echo "launching a shell in the containerized build environment"
	@docker run                                                             \
	    -ti                                                                 \
	    --rm                                                                \
	    -u $$(id -u):$$(id -g)                                              \
	    -v "$$(pwd)/.go:/go"                                                \
	    -v "$$(pwd):/go/src/$(PKG)"                                         \
	    -v "$$(pwd)/bin/$(ARCH):/go/bin"                                    \
	    -v "$$(pwd)/bin/$(ARCH):/go/bin/$$(go env GOOS)_$(ARCH)"            \
	    -v "$$(pwd)/.go/std/$(ARCH):/usr/local/go/pkg/linux_$(ARCH)_static" \
	    -w /go/src/$(PKG)                                                   \
	    $(BUILD_IMAGE)                                                      \
	    /bin/sh $(CMD)

DOTFILE_IMAGE = $(subst :,_,$(subst /,_,$(IMAGE))-$(VERSION))

container: .container-$(DOTFILE_IMAGE) container-name
.container-$(DOTFILE_IMAGE): bin/$(ARCH)/$(BIN) Dockerfile.in
	@sed \
	    -e 's|ARG_BIN|$(BIN)|g' \
	    -e 's|ARG_ARCH|$(ARCH)|g' \
	    -e 's|ARG_FROM|$(BASEIMAGE)|g' \
	    Dockerfile.in > .dockerfile-$(ARCH)
	@docker build -t $(IMAGE):$(VERSION) -f .dockerfile-$(ARCH) .
	@docker images -q $(IMAGE):$(VERSION) > $@

container-name:
	@echo "container: $(IMAGE):$(VERSION)"

push: .push-$(DOTFILE_IMAGE) push-name
.push-$(DOTFILE_IMAGE): .container-$(DOTFILE_IMAGE)
ifeq ($(findstring gcr.io,$(REGISTRY)),gcr.io)
	@gcloud docker -- push $(IMAGE):$(VERSION)
else
	@docker push $(IMAGE):$(VERSION)
endif
	@docker images -q $(IMAGE):$(VERSION) > $@

push-name:
	@echo "pushed: $(IMAGE):$(VERSION)"

version:
	@echo $(VERSION)

test: build-dirs
	@docker run                                                             \
	    -ti                                                                 \
	    --rm                                                                \
	    -u $$(id -u):$$(id -g)                                              \
	    -v "$$(pwd)/.go:/go"                                                \
	    -v "$$(pwd):/go/src/$(PKG)"                                         \
	    -v "$$(pwd)/bin/$(ARCH):/go/bin"                                    \
	    -v "$$(pwd)/.go/std/$(ARCH):/usr/local/go/pkg/linux_$(ARCH)_static" \
	    -w /go/src/$(PKG)                                                   \
	    $(BUILD_IMAGE)                                                      \
	    /bin/sh -c "                                                        \
	        ./build/test.sh $(SRC_DIRS)                                     \

	    "

build-dirs:
	@mkdir -p bin/$(ARCH)
	@mkdir -p .go/src/$(PKG) .go/pkg .go/bin .go/std/$(ARCH)

clean: container-clean bin-clean

container-clean:
	rm -rf .container-* .dockerfile-* .push-*

bin-clean:
	rm -rf .go bin
