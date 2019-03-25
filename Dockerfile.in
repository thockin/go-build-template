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

FROM {ARG_FROM}

ADD bin/{ARG_OS}_{ARG_ARCH}/{ARG_BIN} /{ARG_BIN}

# This would be nicer as `nobody:nobody` but distroless has no such entries.
USER 65535:65535

ENTRYPOINT ["/{ARG_BIN}"]
