# Go app template build environment

This is a skeleton project for a Go application, which captures the best build
techniques I have learned to date.  It uses a Makefile to drive the build (the
universal API to software projects) and a Dockerfile to build a docker image.

This has only been tested on Linux, and depends on Docker to build.

## Customizing it

To use this, simply copy these files and make the following changes:

Makefile:
   - change `BIN` to your binary name
   - change `PKG` to the Go import path of this repo
   - change `REGISTRY` to the Docker registry you want to use
   - maybe change `SRC_DIRS` if youuse some other layout

Dockerfile:
   - change all `myapp` to your binary name

## Building

Run `make` or `make build` to compile your app.  This will use a Docker image
to build your app, with the current directory volume-mounted into place.  This
will store incremental state for the fastest possible build.

Run `make container` to build the container image.  It will calculate the image
tag based on the most recent git tag, and whether the repo is "dirty" since
that tag (see `make version`).

Run `make push` to push the container image to `REGISTRY`.

Run `make clean` to clean up.
