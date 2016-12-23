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


REGISTRY ?= my-registry
ARCH ?= amd64
CONTAINER_PREFIX ?= my-prefix
VERSION ?= 1.0.0

BINARY := hello
OUTPUT_DIR := _output/$(ARCH)
IMAGE := $(REGISTRY)/$(BINARY)-$(ARCH)
STAMP := $(subst /,_,$(IMAGE))
CONTAINER_STAMP := .$(STAMP)-container
PUSH_STAMP := .$(STAMP)-push

all: build

.PHONY: build
build: $(OUTPUT_DIR)/hello

$(OUTPUT_DIR)/hello: hello.c
	@mkdir -p $(@D)
	gcc -o $@ -O3 hello.c

.PHONY: containers
containers: $(CONTAINER_STAMP)

$(CONTAINER_STAMP): $(OUTPUT_DIR)/$(BINARY)
	sed 's|__ARCH__|$(ARCH)|g' Dockerfile.in > $(OUTPUT_DIR)/Dockerfile
	docker build -q -t $(IMAGE):$(VERSION) -f $(OUTPUT_DIR)/Dockerfile . > $@

.PHONY: push
push: $(PUSH_STAMP)

$(PUSH_STAMP): $(CONTAINER_STAMP)
	docker push $(IMAGE):$(VERSION)
	@cat $(CONTAINER_STAMP) > $@

.PHONY: test
test: build
	@$(OUTPUT_DIR)/hello

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)
	rm -f .*-container
	rm -f .*-push
