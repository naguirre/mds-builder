+++
title = "SPI NAND Partitioning"
description = "Flash layout of the 128 MiB SPI NAND used by U-Boot and Linux"
weight = 2
+++

# SPI NAND Partitioning

The 128 MiB SPI NAND is split into four MTD partitions. The first holds the SPL + U-Boot; the others are UBI volumes used at runtime.

| Name   | Size     | MTD   | Size (hex)   | Offset (hex) | Content                                                  |
|--------|----------|-------|--------------|--------------|----------------------------------------------------------|
| boot   | 1 MiB    | mtd0  | `0x0100000`  | `0x0000000`  | SPL + U-Boot (`spi-nand.bin`)                            |
| fota   | 15 MiB   | mtd1  | `0x0f00000`  | `0x0100000`  | UBI: recovery `uImage`, DTB and `uboot.env`              |
| rootfs | 56 MiB   | mtd2  | `0x3800000`  | `0x1000000`  | UBI: main `rootfs.ubifs` (the actual operating system)   |
| data   | 56 MiB   | mtd3  | `0x3800000`  | `0x4800000`  | UBI: scratch space for downloaded firmware images        |
| **Σ**  | **128 MiB** |    | `0x8000000`  |              |                                                          |

> The exact byte sizes come from `kernel_defconfig` and the device-tree partitions node; double-check both if you change the layout.

## Why this split

This layout supports the [A/B firmware update strategy](@/software/fota.md):

- `boot` is updated in place when reflashing the bootloader.
- `fota` carries a minimal recovery image (initramfs + kernel) able to reflash `rootfs` even when the main system is broken.
- `rootfs` is the running system; it is mounted read-write as UBIFS.
- `data` is used as a staging area to drop a new `rootfs.ubifs` before applying it (over `ubiupdatevol`).

## UBI parameters

Measured on the board:

```text
PEB size:        131072 bytes (128 KiB)
LEB size:        126976 bytes
min I/O size:    2048
sub-page size:   2048
VID header off:  2048
data offset:     4096
good PEBs:       448 (rootfs / data), 1016 (full chip)
```

When generating a UBIFS image in Buildroot, the LEB size of the image **must match** the LEB size of the runtime UBI device, otherwise mounting fails with:

```text
UBIFS error: LEB size mismatch: 129024 in superblock, 126976 real
```

Set the Buildroot UBIFS LEB size accordingly under `Filesystem images → ubifs`.
