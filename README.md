# Go app template build environment
[![Build Status](https://travis-ci.org/thockin/go-build-template.svg?branch=master)](https://travis-ci.org/thockin/go-build-template) 

This is a skeleton project for a Go application, which captures the best build
techniques I have learned to date.  It uses a Makefile to drive the build (the
universal API to software projects) and a Dockerfile to build a docker image.

This has only been tested on Linux, and depends on Docker to build.

## Customizing it

To use this, simply copy these files and make the following changes:

Makefile:
   - change `BIN` to your binary name
   - rename `cmd/myapp` to `cmd/$BIN`
   - change `REGISTRY` to the Docker registry you want to use
   - maybe change `SRC_DIRS` if you use some other layout
   - choose a strategy for `VERSION` values - git tags or manual

Dockerfile.in:
   - maybe change or remove the `USER` if you need

## Go Modules

This assumes the use of go modules (which will be the default for all Go builds
as of Go 1.13) and vendoring (which reasonable minds might disagree about).
You will need to run `go mod vendor` to create a `vendor` directory when you
have dependencies.

## Building

Run `make` or `make build` to compile your app.  This will use a Docker image
to build your app, with the current directory volume-mounted into place.  This
will store incremental state for the fastest possible build.  Run `make
all-build` to build for all architectures.

Run `make container` to build the container image.  It will calculate the image
tag based on the most recent git tag, and whether the repo is "dirty" since
that tag (see `make version`).  Run `make all-container` to build containers
for all architectures.

Run `make push` to push the container image to `REGISTRY`.  Run `make all-push`
to push the container images for all architectures.

Run `make clean` to clean up.
