+++
title = "Machines"
description = "Supported Buildroot defconfigs"
weight = 3
+++

# Machines

A *machine* is just a Buildroot defconfig — concretely, `buildroot_config/mds_<machine>_defconfig`. Pick one with `MACHINE=<machine>` on the `make` command line.

## Network player (default)

| Machine                          | Purpose                                                              |
|----------------------------------|----------------------------------------------------------------------|
| `network_player`                 | Default: the main rootfs (Linux + UBIFS) shipped on the device       |
| `mds_network_player_bootstrap`   | Initial bring-up image — see [Bootstrap](/flashing/bootstrap)        |
| `mds_network_player_fota`        | Recovery initramfs used by the FOTA partition                        |
| `mds_network_player_v2`          | Work in progress for the next hardware revision (see `README_v2.md`) |
| `lmds_network_player`            | Variant defconfig (legacy / experimental)                            |
| `lmds_binky`                     | Variant defconfig (legacy / experimental)                            |

## Other targets

These are kept in-tree to validate the BR2_EXTERNAL packages on more accessible hardware:

| Machine                       | Board                                          |
|-------------------------------|------------------------------------------------|
| `mds_raspberrypi4`            | Raspberry Pi 4                                 |
| `mds_rpi4`                    | Raspberry Pi 4 (alternative defconfig)         |
| `mds_rpi3`                    | Raspberry Pi 3                                 |
| `mds_raspberrypi_zero2w`      | Raspberry Pi Zero 2 W                          |
| `mds_raspberrypi_zerow`       | Raspberry Pi Zero W                            |
| `mds_rg35xx`                  | Anbernic RG35XX (used for music apps prototyping) |
| `mds_v851s_lizard`            | Allwinner V851s "Lizard" dev board              |

## How `MACHINE` maps onto the build

For a given `MACHINE=foo`, the Makefile picks up:

- defconfig: `buildroot_config/mds_foo_defconfig`
- output directory: `build/output/foo/`
- board files: `mds_external/board/<foo>/` (when present)

Look at `mds_external/board/mds_network_player/` for the most complete example, including:

- `kernel_defconfig`, `linux-patches/`
- `u-boot_defconfig`, `u-boot_devicetree.dts`, `uboot.env`, `uboot-patches/`
- `image.its`, `mknandboot.sh`, `f1c100_uboot_spinand.sh`, `post-images.sh`
- `rootfs_overlay/`, `fota_rootfs_overlay/`
