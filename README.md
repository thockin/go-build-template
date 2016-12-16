# Go app template build environment

This is a skeleton project for a Go application, which captures the best build
techniques I have learned to date.  It uses a Makefile to drive the build (the
universal API to software projects) and a Dockerfile to build a docker image.

This has only been tested on Linux, and depends on Docker to build.

## Customizing it

To use this, simply copy these files and make the following changes:

Makefile:
- change `BINARIES` to list your binaries
- change `PKG` to the Go import path of this repo
- change `REGISTRY` to the Docker registry you want to use
- choose a strategy for `VERSION` values - git tags or manual

Dockerfile.BINARY:
- change the `MAINTAINER` to you
- maybe change or remove the `USER` if you need

Additional images
- Additional images to be build should be listed in `IMAGES` and placed in the
  `images/` directory. See [`images/Makefile`](images/Makefile) for more
  details.

## Building

Run `make` or `make build` to compile your app.  This will use a Docker image to
build your app, with the current directory volume-mounted into place.  This will
store incremental state for the fastest possible build.  Run `make all-build` to
build for all architectures.

Run `make containers` to build the container image.  It will calculate the image
tag based on the most recent git tag, and whether the repo is "dirty" since that
tag (see `make version`).  Run `make all-containers` to build containers for all
architectures.

Run `make push` to push the container images to `REGISTRY`.  Run `make all-push`
to push the container images for all architectures.

Run `make clean` to clean up.

See `make help` for more details.
