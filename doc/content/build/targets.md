+++
title = "Make Targets"
description = "Reference for every target exposed by the top-level Makefile"
weight = 2
+++

# Make Targets

The top-level Makefile is a thin wrapper around Buildroot. All targets accept the `CONTAINER=1` switch to run inside the Docker image instead of natively.

## Variables

| Variable             | Default                              | Description                                          |
|----------------------|--------------------------------------|------------------------------------------------------|
| `MACHINE`            | `network_player`                     | Selects the defconfig at `buildroot_config/mds_${MACHINE}_defconfig` |
| `BUILDROOT_VERSION`  | `2026.02.1`                          | Cloned from the official Buildroot Git repository    |
| `CONTAINER`          | `0`                                  | If `1`, every build command runs inside Docker       |
| `CONTAINER_ENGINE`   | `docker`                             | Override to `podman`, etc.                           |
| `WORKSPACE`          | current directory                    | Used to anchor `build/` and `mds_external/`          |
| `OUTPUT_DIR`         | `build/output/${MACHINE}`            | Buildroot `O=` directory                             |
| `EXTERNAL_REPOSITORIES` | `mds_external`                    | Passed as `BR2_EXTERNAL=` to Buildroot               |

A small `user.env` file at the repo root is auto-included to pin these.

## Top-level targets

### `make build`

Default target. Downloads Buildroot if needed, copies the selected defconfig, configures Buildroot, then runs the build.

```bash
make build                                # network_player
make build MACHINE=mds_network_player_fota
make build MACHINE=mds_network_player_bootstrap
make build CONTAINER=1
```

### `make build-<package>`

Runs `make <package>` inside the Buildroot output directory. Useful to rebuild a single package without going through the whole tree.

Examples:

```bash
make build-linux-rebuild     # rebuild the kernel
make build-uboot-rebuild     # rebuild U-Boot
make build-linux-menuconfig  # interactive kernel config
```

### `make config`

(Re)generates the Buildroot configuration from the defconfig. Run this once if you change anything under `buildroot_config/` or `mds_external/`.

### `make menuconfig`

Opens Buildroot's `menuconfig`. On exit, it runs `savedefconfig` and copies the result back into `buildroot_config/mds_${MACHINE}_defconfig`, so any change you make through the UI is captured in version control.

### `make sdk`

Builds a relocatable SDK tarball under `build/output/${MACHINE}/images/`. The SDK is named:

```
sdk-mds-${MACHINE}-$(git describe --tags --dirty --always)
```

Use it to cross-compile out-of-tree code against the exact toolchain that produced the firmware.

### `make clean` / `make clean-all`

- `clean` removes the output directory for the current `MACHINE` (`build/output/<machine>`).
- `clean-all` wipes **every** `build/output/*` directory.

The Buildroot download cache and downloaded sources are preserved.

## Container helpers

| Target              | Effect                                                                |
|---------------------|-----------------------------------------------------------------------|
| `container-image`   | Build the Docker image `mds_builder_image:latest`                     |
| `containter-shell`  | Drop into an interactive shell inside the container                   |
| `container-rm`      | Remove the Docker image                                               |

## Bootstrap helper

```bash
make bootstrap
```

…runs `bootstrap.sh`, which uses `sunxi-fel` to load the bootstrap image into RAM over USB. See [Bootstrap](/flashing/bootstrap) for the end-to-end flow.

## Help

`make help` prints the same table generated from the `##` comments in the Makefile.
