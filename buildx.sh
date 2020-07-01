#!/bin/bash -ex

VERSION="1.dev"
EPICS="7.0.4"
# mark this flavour with the special `latest` tag:
LATEST_FLAVOUR=debian
PLATFORMS=linux/amd64,linux/386,linux/arm64/v8,linux/arm/v7

for flavour in scratch debian; do
  echo " ============= $flavour ============= "
  if [ "${flavour}" = "${LATEST_FLAVOUR}" ]; then
    ADD_TAG="-t pklaus/catools:latest"
  else
    ADD_TAG=""
  fi
  TAGS="-t pklaus/catools:$flavour -t pklaus/catools:${VERSION}-${EPICS}-$flavour $ADD_TAG"
  docker buildx build --build-arg FLAVOUR=$flavour --platform $PLATFORMS $TAGS "$@" .
done
