# syntax=docker/dockerfile:experimental

FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND noninteractive

ARG HTTPS_PROXY
ARG HTTP_PROXY

ENV http_proxy $HTTP_PROXY
ENV https_proxy $HTTPS_PROXY

RUN apt-get update && apt-get install build-essential curl git pkg-config libfuse-dev fuse -y && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh; \
    sh /tmp/rustup-init.sh --default-toolchain nightly-2021-12-23 -y; \
    rm /tmp/rustup-init.sh; \
    /root/.cargo/bin/cargo --version
ENV PATH "/root/.cargo/bin:${PATH}"

RUN if [ -n "$HTTP_PROXY" ]; then echo "[http]\n\
proxy = \"${HTTP_PROXY}\"\n\
"\
> /root/.cargo/config ; fi

COPY . /toda-build

WORKDIR /toda-build

ENV RUSTFLAGS "-Z relro-level=full"
RUN --mount=type=cache,target=/toda-build/target \
    --mount=type=cache,target=/root/.cargo/registry \
    cargo build --release

RUN --mount=type=cache,target=/toda-build/target \
    cp /toda-build/target/release/toda /toda