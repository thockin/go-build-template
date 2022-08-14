# Go app template build environment

This is a skeleton project for a Go application, which captures the best build
techniques I have learned to date.  It uses a Makefile to drive the build (the
universal API to software projects) and a Dockerfile to build a docker image.

This has only been tested on Linux, and depends on Docker buildx to build.

## Customizing it

To use this, simply copy this repo and make the following changes:

Makefile:
   - change `BINS` to your binary name(s)
   - replace `cmd/myapp-*` with one directory for each of your `BINS`
   - change `REGISTRY` to the Docker registry you want to use
   - choose a strategy for `VERSION` values - git tags or manual
   - maybe change `ALL_PLATFORMS`
   - maybe change `BASE_IMAGE` (it must be a manifest-list with support for all
     platforms in `ALL_PLATFORMS`)

Dockerfile.in:
   - maybe change or remove the `USER` if you need

## Go Modules

This assumes the use of go modules (which is the default for all Go builds
as of Go 1.13).

## Dependencies

This includes go-licenses and golangci-lint, but they are kept in the `tools`
sub-module.  If you don't want those (or their dependencies, they can be
removed.

## Building

Run `make` or `make build` to compile your app.  This will use docker buildx
(which you need to have installed) to build your app, with the current
directory volume-mounted into place.  This will store incremental state for the
fastest possible build.  Run `make all-build` to build for all architectures.

Run `make container` to build the container image.  It will calculate the image
tag based on the most recent git tag, and whether the repo is "dirty" since
that tag (see `make version`).  Run `make all-container` to build containers
for all supported architectures.

Run `make push` to push the container image to `REGISTRY`.  Run `make all-push`
to push the container images for all architectures.

Run `make manifest-list` to build and push all containers for all
architectures, and then publish a manifest-list for them.

Run `make clean` to clean up.

Run `make help` to get a list of available targets.

## Testing

Run `make test` and `make lint` to run tests and linters, respectively.  Like
building, this will use docker to execute.

The golangci-lint tool looks for configuration in `.golangci.yaml`.  If that
file is not provided, it will use its own built-in defaults.
