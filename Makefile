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

#
# `make help` will show commonly used targets.
#

# Golang package.
PKG := github.com/bowei/go-build-template

# List of binaries to build. You must have a matching Dockerfile.BINARY
# for each BINARY.
BINARIES := app1 app2
# List of additional images to build. These are located in the images/
# directory.
IMAGES := hello

# Registry to push to.
REGISTRY ?= my-registry
# Default architecture to build for.
ARCH ?= amd64
# Image to use for building.
BUILD_IMAGE ?= golang:1.7-alpine
# Containers will be named: $(CONTAINER_PREFIX)-$(BINARY)-$(ARCH):$(VERSION)
CONTAINER_PREFIX ?= my-prefix

# This version-strategy uses git tags to set the version string
VERSION ?= $(shell git describe --tags --always --dirty)
# This version-strategy uses a manual value to set the version string
#VERSION := 1.2.3

# Set to 1 to print more verbose output from the build.
VERBOSE ?= 0

# Include standard build rules.
include rules.mk
