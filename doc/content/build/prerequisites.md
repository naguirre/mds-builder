+++
title = "Prerequisites"
description = "Host packages and Docker option"
weight = 1
+++

# Prerequisites

Two flavours are supported: building natively on a Linux host, or building inside the provided Docker container.

## Native build

Buildroot itself documents the [minimum required host packages](https://buildroot.org/downloads/manual/manual.html#requirement). The Docker image used by this project mirrors what is needed; on Debian / Ubuntu it boils down to:

```bash
sudo apt update
sudo apt install -y \
    build-essential bash bc binutils bzip2 cpio g++ gcc git gzip \
    libncurses5-dev libdevmapper-dev libsystemd-dev libssl-dev libfdt-dev \
    make mercurial whois patch perl python3 python3-setuptools python3-dev \
    rsync sed tar unzip wget bison flex swig file mtools u-boot-tools curl
```

For flashing you will additionally want:

- [`sunxi-tools`](https://github.com/linux-sunxi/sunxi-tools) — provides `sunxi-fel`, used to push images into RAM over USB FEL.
- A serial console tool — `picocom`, `minicom`, `screen` or similar.

## Containerised build

The [Dockerfile](https://github.com/naguirre/mds-builder/blob/main/Dockerfile) provides a reproducible Ubuntu 24.04 environment that already contains every host package needed by Buildroot.

Build the image once:

```bash
make container-image
```

Then prefix any build target with `CONTAINER=1`:

```bash
make build CONTAINER=1
make build-linux-rebuild CONTAINER=1
```

Internally this runs:

```bash
docker run -it --rm \
    --volume="$PWD:$PWD" \
    -v mds-builder-build:$PWD/build \
    --workdir="$PWD" \
    mds_builder_image:latest <command>
```

A named volume `mds-builder-build` is mounted at `$PWD/build` so the long Buildroot output tree survives container restarts without being stored inside the layered filesystem.

## Container engine

The default engine is `docker`. To use Podman or any other compatible engine:

```bash
make build CONTAINER=1 CONTAINER_ENGINE=podman
```

You can also drop into a shell inside the container:

```bash
make containter-shell
```

## `user.env`

If a `user.env` file exists at the repo root, it is automatically `include`d by the Makefile. Use it to pin your favourite defaults, e.g.:

```makefile
CONTAINER       = 1
CONTAINER_ENGINE = podman
MACHINE         = network_player
```
