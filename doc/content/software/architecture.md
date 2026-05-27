+++
title = "Architecture"
description = "Overall software architecture of the network player"
weight = 1
+++

# Architecture

## Components

{% mermaid() %}
flowchart LR
    subgraph ESP["ESP32-C3"]
        ESPFW["ESP-Hosted firmware<br/>Wi-Fi + BLE 5.0"]
    end

    subgraph F1C["Allwinner f1c200s"]
        direction TB
        subgraph LINUX["Linux 6.x rootfs (musl)"]
            SPDIF["sun4i-spdif"]
            ESPH["esp-hosted-ng"]
            GETHER["g_ether"]
        end
        UBOOT["U-Boot 2026.04"]
        SPL["U-Boot SPL"]
        UBOOT --> LINUX
        SPL --> UBOOT
    end

    NAND[("SPI NAND 128 MiB<br/>boot / fota / rootfs / data")]

    ESPFW <-->|SPI + UART| ESPH
    NAND --> SPL
    SPDIF -->|SPDIF| SPDIFOUT([SPDIF out])
    GETHER -->|USB| USBC([USB-C host])
{% end %}

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
