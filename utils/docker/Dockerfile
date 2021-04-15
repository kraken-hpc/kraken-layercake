### -*- Mode: Dockerfile; fill-column: 80; comment-auto-fill-only-comments: t; tab-width: 4 -*-
################################################################################
# Dockerfile: container definitions for Kraken/Layercake
# 
# Original Author: Micheal Jennings <mej@lanl.gov>
# Maintainer: J. Lowell Wofford <lowell@lanl.gov>
# 
# This software is open source software available under the BSD-3 license.
# Copyright (c) 2021, Triad National Security, LLC
# See LICENSE file for details.
# 
################################################################################

### Build Arguments (override via "--build-arg")
ARG GOVER="1.15"
ARG ALPINE="3.13"

################################################################################
### Stage #1:  Alpine-based Go dev env with Kraken/Layercake built & installed
################################################################################
FROM docker.io/library/golang:${GOVER}-alpine AS kraken-layercake-build
LABEL maintainer="J. Lowell Wofford <lowell@lanl.gov>"

ARG GOARCH="${GOARCH:-amd64}"
ARG GOOS="${GOOS:-linux}"
WORKDIR "/src"
COPY . .

# install package dependencies
RUN apk add --no-cache \
      coreutils \
      syslinux \
      git \
      cpio \
      openssh \
      openssh-keygen \
      xz \
      rsync \
      bash 

# build kraken-layercake
RUN env \
    && go mod download \
    && go build ./cmd/kraken-layercake \
    && cp -v kraken-layercake /sbin/kraken-layercake

# setup tftp
RUN mkdir -p /tftp/amd64/powerapi/pxelinux.cfg \
    && cp -av utils/docker/pxelinux-default.tpl /tftp/amd64/powerapi/pxelinux.cfg/default.tpl \
    && cp -av /usr/share/syslinux/* /tftp/amd64/powerapi \
    && cp -av utils/layer0 /tftp/layer0

# build layer0-base
# note: we have to use -t because `mktemp` is not gnu compliant
RUN bash utils/layer0/build-layer0-base.sh -g -o /tftp/amd64/powerapi/layer0-base.gz -t /tmp/layer0-base "$GOARCH"

# build layer0-config (stubs)
RUN cp -av utils/docker/config /tftp/layer0/config \
    && ssh-keygen -N "" -t rsa -b 4096 -f /root/.ssh/cluster \
    && cp -av /root/.ssh/cluster.pub /tftp/layer0/config/authorized_keys \
    && bash utils/layer0/build-layer0-config.sh -g -t /tmp/layer0-config -o /tftp/amd64/powerapi/layer0-conf.gz /tftp/layer0/config

ENTRYPOINT [ "/sbin/kraken-layercake" ]
CMD [ "-h" ]


################################################################################
### Stage #2:  Pure Alpine container (no Go) with Kraken/Layercake copied in
###
### This container is intended to provide a runnable kraken-layercake environment.
### You will likely want ot pass in /config.yaml /state.json and various /tftp/** files.
### E.g. podman run --net=host -v tftp:/tftp -v etc/kraken:/etc/kraken kraken-layercake
###
################################################################################
FROM docker.io/library/alpine:${ALPINE} AS kraken-layercake
LABEL maintainer="J. Lowell Wofford <lowell@lanl.gov>"

COPY --from=kraken-layercake-build /sbin/kraken-layercake /sbin/kraken-layercake
COPY --from=kraken-layercake-build /tftp /tftp

# add dependencies
# we want these so you can run layer0 scripts inside the container
RUN apk add --no-cache \
      bash \
      cpio \
      xz

# set up /etc/kraken
RUN env \
    && mkdir -p /etc/kraken \
    && echo '{}' > /etc/kraken/state.json \
    && /sbin/kraken-layercake -state /etc/kraken/state.json -printrc > /etc/kraken/config.yaml

ENTRYPOINT [ "/sbin/kraken-layercake" ]
CMD [ "-config", "/etc/kraken/config.yaml" ]
