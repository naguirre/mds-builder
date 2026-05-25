+++
title = "Architecture"
description = "Overall software architecture of the network player"
weight = 1
+++

# Architecture

## Components

```
┌───────────────────────────────────────────────────────────────────┐
│                       Manufacture du Son                          │
│                                                                   │
│   ┌──────────────┐                ┌─────────────────────────────┐ │
│   │  ESP32-C3    │  SPI / UART    │       Allwinner f1c200s     │ │
│   │  ESP-Hosted  │ ◀────────────▶ │  ┌───────────────────────┐  │ │
│   │  (Wi-Fi+BLE) │                │  │  Linux 6.x (rootfs)   │  │ │
│   └──────────────┘                │  │  ┌─────────────────┐  │  │ │
│                                   │  │  │ sun4i-spdif     │──┼──┼─▶ SPDIF out
│                                   │  │  │ esp-hosted-ng   │  │  │ │
│                                   │  │  │ g_ether         │──┼──┼─▶ USB-C (host)
│                                   │  │  └─────────────────┘  │  │ │
│                                   │  └───────────────────────┘  │ │
│                                   │  ┌───────────────────────┐  │ │
│                                   │  │ U-Boot 2024.04        │  │ │
│                                   │  ├───────────────────────┤  │ │
│                                   │  │ U-Boot SPL            │  │ │
│                                   │  └───────────────────────┘  │ │
│                                   │            ▲                │ │
│                                   │            │                │ │
│                                   │   ┌────────┴───────────┐    │ │
│                                   │   │   SPI NAND 128 MiB │    │ │
│                                   │   │  boot/fota/rootfs/ │    │ │
│                                   │   │  data partitions   │    │ │
│                                   │   └────────────────────┘    │ │
│                                   └─────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

## Sources of truth

Everything that ends up on the device is generated from this repository through Buildroot:

- `buildroot_config/mds_<machine>_defconfig` — Buildroot top-level config
- `mds_external/` — `BR2_EXTERNAL` tree (boards, packages, defconfigs, overlays)
- `mds_external/board/mds_network_player/` — board files used by the network player:
  - `u-boot_defconfig`, `u-boot_devicetree.dts`, `uboot.env`
  - `kernel_defconfig`, `linux-patches/`, `uboot-patches/`
  - `image.its` — FIT image description
  - `mknandboot.sh`, `f1c100_uboot_spinand.sh` — SPL/U-Boot relocation for SPI NAND boot
  - `rootfs_overlay/`, `fota_rootfs_overlay/` — files added on top of the Buildroot rootfs
  - `post-images.sh`, `post-images-fota.sh` — post-build image assembly

## Userspace highlights

- **`sun4i-spdif`** — kernel module driving the SPDIF output. The driver lives in mainline; see `sound/soc/sunxi/sun4i-spdif.ko`.
- **`g_ether`** — USB gadget that exposes the board to the host as an Ethernet device (default IP `192.168.2.2`).
- **`esp-hosted-ng`** — host driver that runs over SPI to talk to the ESP32-C3 firmware. The repository vendors the [ESP-Hosted](https://github.com/espressif/esp-hosted) sources under `src/esp-hosted/`.

## Why musl

Buildroot is configured with the **musl** C library. This keeps the rootfs small and aligned with the ARMv5TE / 64 MiB constraints of the f1c200s.
