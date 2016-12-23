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

# Each image/ Makefile MUST provide the following targets:
#
# build      : build the source code
# containers : create the Docker containers
# test       : test the containers
# push       : push the containers to the registry
#
# The following variables are exported to the submake process:
#
# REGISTRY : registry to push to
# ARCH     : architecture to build
# CONTAINER_PREFIX: prefix for container names
# VERSION  : version, e.g. tag for the containers
# VERBOSE  : will be 1 if running in verbose mode

# List of image directories to build.
IMAGES ?=

all: build

.PHONY: build
build:
	@$(MAKE) $(addprefix build-,$(IMAGES))

.PHONY: containers
containers:
	@$(MAKE) $(addprefix containers-,$(IMAGES))

.PHONY: push
push:
	@$(MAKE) $(addprefix push-,$(IMAGES))

.PHONY: test
test:
	@$(MAKE) $(addprefix test-,$(IMAGES))

.PHONY: clean
clean:
	@$(MAKE) $(addprefix clean-,$(IMAGES))

# Suffix rules to dispatch to the appropriate subdirectory.
build-%:
	@$(MAKE) -C $* build

containers-%:
	@$(MAKE) -C $* containers

push-%:
	@$(MAKE) -C $* push

test-%:
	@$(MAKE) -C $* test

clean-%:
	@$(MAKE) -C $* clean
