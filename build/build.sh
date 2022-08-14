#!/bin/sh

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

set -o errexit
set -o nounset
set -o pipefail

if [ -z "${OS:-}" ]; then
    echo "OS must be set"
    exit 1
fi
if [ -z "${ARCH:-}" ]; then
    echo "ARCH must be set"
    exit 1
fi
if [ -z "${VERSION:-}" ]; then
    echo "VERSION must be set"
    exit 1
fi

export CGO_ENABLED=0
export GOARCH="${ARCH}"
export GOOS="${OS}"
export GO111MODULE=on

if [[ "${DEBUG:-}" == 1 ]]; then
    # Debugging - disable optimizations and inlining
    gogcflags="all=-N -l"
    goasmflags=""
    goldflags=""
else
    # Not debugging - trim paths, disable symbols and DWARF.
    goasmflags="all=-trimpath=$(pwd)"
    gogcflags="all=-trimpath=$(pwd)"
    goldflags="-s -w"
fi

always_ldflags="-X $(go list -m)/pkg/version.Version=${VERSION}"
go install                                                      \
    -installsuffix "static"                                     \
    -gcflags="${gogcflags}"                                     \
    -asmflags="${goasmflags}"                                   \
    -ldflags="${always_ldflags} ${goldflags}"                   \
    "$@"
