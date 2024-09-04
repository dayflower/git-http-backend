# syntax=docker/dockerfile:1

#### Build stage

ARG GO_VERSION=1.23

# must follow the version used in [bitnami/git](https://hub.docker.com/r/bitnami/git) image
ARG OS_VARIANT=-bookworm

ARG GIT_VERSION=2.46.0

ARG TARGETOS TARGETARCH

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}${OS_VARIANT} AS build

WORKDIR /src

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download -x

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    CGO_ENABLED=1 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /bin/server .

#### Package stage

FROM bitnami/git:${GIT_VERSION}

COPY /docker/rootfs /
COPY --from=build /bin/server /usr/bin/git-http-backend

RUN rm -f /opt/bitnami/git/scripts/entrypoint.sh \
    && mkdir -p /repositories

USER nobody

EXPOSE 8080

VOLUME ["/repositories"]

ENV SERVER_ADDRESS=:8080 \
    PROJECT_ROOT=/repositories \
    READ_ONLY= \
    REQUIRE_AUTH= \
    AUTH_USERNAME= \
    AUTH_PASSWORD= \
    GIT_BIN_PATH=

ENTRYPOINT ["/opt/git-http-backend/scripts/entrypoint.sh"]
