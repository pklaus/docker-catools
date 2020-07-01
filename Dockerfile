ARG FLAVOUR=scratch

## =================================
# Collect list of (non-directory)
# contents of a blank Debian image:
FROM debian:10-slim AS blank-debian
RUN find / -not -type d > /filelist
## =================================

## ============================================================================
# Get the catools from a full-blown EPICS Base 7.0.4 Debian Image
# Select the binaries and the libraries they depend on using the dockerize tool
# which uses objdump and consecutively ld-linux to figure out the depencencies
# in a recursive fashion to put only what's immediately needed into the final images.
FROM pklaus/epics_base:7.0.4_debian AS builder
# default user in the above image is "scs", so go back to root:
ARG FLAVOUR
ENV FLAVOUR=${FLAVOUR}
USER root
WORKDIR /
SHELL ["/bin/bash", "-e", "-c"]
#
RUN apt-get update && apt-get install -yq python python-pip rsync \
 && pip install https://github.com/larsks/dockerize/archive/a903419.zip
#
# create folder to contain everything we want in our final image:
RUN mkdir /catools_root
# copy executables and libraries to that folder
RUN for executable in $(ls /epics/base/bin/${EPICS_HOST_ARCH}/ | grep -v '\.' | grep -v S99); do \
      echo "------------------------------------------------------------------"; \
      echo /epics/base/bin/${EPICS_HOST_ARCH}/$executable; \
      dockerize \
        -a /epics/base/{db,} \
        -a /epics/base/{dbd,} \
        -L preserve \
        -n -o /catools_root \
        --verbose \
        /epics/base/bin/${EPICS_HOST_ARCH}/$executable; \
        rm /catools_root/Dockerfile; \
    done
# If we transfer the files to a clean base image, leave out
# any files that exist already in order to save space:
COPY --from=blank-debian /filelist /filelist.blank-debian
RUN if [ "${FLAVOUR}" == "debian" ]; then \
      #cat /filelist.blank-debian; exit 1; \
      rsync -avz --exclude-from /filelist.blank-debian /catools_root/ /catools_root_tmp/; \
      rm -rf /catools_root; \
      mv /catools_root_tmp /catools_root; \
    fi
#
## for debugging: list all files in /catools_root and cancel build
#RUN find /catools_root && false
## ============================================================================

## ============================================================================
# Multi-Arch Preparations (various FROM to set ENV EPICS_HOST_ARCH differently)
#
# Scratch (empty base image)
FROM scratch as base-scratch
FROM base-scratch AS base-scratch-amd64
ENV EPICS_HOST_ARCH=linux-x86_64
FROM base-scratch AS base-scratch-386
ENV EPICS_HOST_ARCH=linux-x86
FROM base-scratch AS base-scratch-arm64
ENV EPICS_HOST_ARCH=linux-arm
FROM base-scratch AS base-scratch-arm
ENV EPICS_HOST_ARCH=linux-arm
#
# Debian
FROM debian:10-slim AS base-debian
FROM base-debian AS base-debian-amd64
ENV EPICS_HOST_ARCH=linux-x86_64
FROM base-debian AS base-debian-386
ENV EPICS_HOST_ARCH=linux-x86
FROM base-debian AS base-debian-arm64
ENV EPICS_HOST_ARCH=linux-arm
FROM base-debian AS base-debian-arm
ENV EPICS_HOST_ARCH=linux-arm
## ============================================================================

## ====================================================
# Final Build Stage - From {scratch,alpine,debian}-base
FROM base-${FLAVOUR}-${TARGETARCH} as final
COPY --from=builder /catools_root /
ENV PATH /epics/base/bin/${EPICS_HOST_ARCH}:$PATH
WORKDIR /epics/base/bin/${EPICS_HOST_ARCH}
## ====================================================
