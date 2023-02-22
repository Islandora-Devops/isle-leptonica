# ISLE: Leptonica <!-- omit in toc -->

[![LICENSE](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](./LICENSE)
[![CI](https://github.com/Islandora-Devops/isle-leptonica/actions/workflows/ci.yml/badge.svg)](https://github.com/Islandora-Devops/isle-leptonica/actions/workflows/ci.yml)

- [Introduction](#introduction)
- [Requirements](#requirements)
- [Building](#building)
  - [Local Registry](#local-registry)
- [Cleanup](#cleanup)

## Introduction

This repository provides the `islandora/leptonica` image which only exists
to provide a custom Alpine APK package(s).

Since this does not change often and takes a very long time to cross compile for
both platforms it's been moved to it's own repository.

## Requirements

To build the Docker images using the provided Gradle build scripts requires:

- [Docker 19.03+](https://docs.docker.com/get-docker/)
- [mkcert](https://github.com/FiloSottile/mkcert)

## Building

You can build your host platform locally using the default builder like so.

```bash
docker buildx bake --builder default
```

### Local Registry

To test multi-arch builds and remote build caching requires setting up a local
registry.

You need to generate certificates for the local registry:

```bash
mkcert -install
cp $(mkcert -CAROOT)/* certs/
mkcert -cert-file ./certs/cert.pem -key-file ./certs/privkey.pem "*.islandora.dev" "islandora.dev" "*.islandora.io" "islandora.io" "*.islandora.info" "islandora.info" "localhost" "127.0.0.1" "::1"
```

A docker compose file is provided to setup a local registry:

```bash
docker compose up -d
```

Once the registry is setup can create a builder:

```bash
docker buildx create \
  --bootstrap \
  --config buildkitd.toml \
  --driver-opt "image=moby/buildkit:v0.11.1,network=isle-leptonica" \
  --name "isle-leptonica"
```

Now you can perform the build locally by pushing to the local registry:

```bash
REGISTRY=islandora.io docker buildx bake --builder isle-leptonica ci --push
```

## Cleanup

Remove the builder:

```bash
docker buildx rm isle-leptonica
```

Remove the registry:

```bash
docker compose down -v
```
