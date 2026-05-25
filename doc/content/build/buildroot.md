+++
title = "Buildroot External Tree"
description = "How BR2_EXTERNAL is organised in this repository"
weight = 4
+++

# Buildroot External Tree

The repository provides a [BR2_EXTERNAL](https://buildroot.org/downloads/manual/manual.html#outside-br-custom) tree at `mds_external/`. Buildroot picks it up automatically via the Makefile (`BR2_EXTERNAL=$(EXTERNAL_REPOSITORIES)`).

## Layout

```
mds_external/
├── external.desc         # 'name: MDS' — registers the tree
├── Config.in             # Kconfig fragment, sourced into Buildroot
├── external.mk           # Make snippet, sourced into Buildroot
├── local.mk              # Optional local overrides
└── board/
    ├── mds_network_player/
    ├── mds_network_player_v2/
    ├── raspberrypizero2w/
    └── v851s_lizard/
```

## `external.desc`

```ini
name: MDS
```

This name surfaces in `BR2_EXTERNAL_MDS_PATH`, which is used everywhere else in the tree to reference files.

## Board directories

Each subdirectory under `board/<machine>/` carries everything that is *not* a Buildroot package but needs to ship with that machine:

| File                              | Purpose                                                            |
|-----------------------------------|--------------------------------------------------------------------|
| `u-boot_defconfig`                | U-Boot config for the production target                            |
| `u-boot-bootstrap_defconfig`      | U-Boot config for the bootstrap image                              |
| `u-boot_devicetree.dts`           | Custom DTS injected into U-Boot                                    |
| `uboot.env`, `uboot.bootstrap.env`| U-Boot environment scripts                                         |
| `uboot-patches/`                  | Patches applied on top of mainline U-Boot                          |
| `kernel_defconfig`                | Linux config                                                       |
| `linux-patches/`                  | Patches applied on top of mainline Linux                           |
| `image.its`                       | FIT image description (kernel + DTB + initramfs)                   |
| `mknandboot.sh`                   | Re-packs `u-boot-with-spl.bin` for SPI NAND boot                   |
| `f1c100_uboot_spinand.sh`         | Companion script for SPL relocation                                |
| `post-images.sh`                  | Buildroot `post-image` hook for the regular rootfs                 |
| `post-images-fota.sh`             | Buildroot `post-image` hook for the FOTA initramfs                 |
| `rootfs_overlay/`                 | Files copied verbatim into the final rootfs                        |
| `fota_rootfs_overlay/`            | Files copied verbatim into the FOTA initramfs                      |
| `boot_esp32.sh`, `flash_esp32.sh` | Helpers for the ESP32-C3 companion firmware                        |

## Editing the kernel / U-Boot config

To change the in-tree kernel config:

```bash
make build-linux-menuconfig
make build-linux-savedefconfig
cp build/output/network_player/build/linux-*/defconfig \
   mds_external/board/mds_network_player/kernel_defconfig
```

Same idea for U-Boot:

```bash
make build-uboot-menuconfig
make build-uboot-savedefconfig
cp build/output/network_player/build/uboot-*/defconfig \
   mds_external/board/mds_network_player/u-boot_defconfig
```

(There are commented-out helper targets for this in the Makefile — feel free to revive them when stable.)
