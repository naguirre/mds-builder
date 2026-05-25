+++
title = "Software"
description = "Software stack and architecture of the network player"
sort_by = "weight"
weight = 2
template = "section.html"
page_template = "page.html"
+++

# Software

The firmware is a fully custom Linux distribution assembled with [Buildroot](https://buildroot.org/). It bundles the bootloader, the kernel, a UBIFS rootfs and a small recovery initramfs, all built from sources and reproducible from the [mds-builder](https://github.com/naguirre/mds-builder) repository.

## Stack at a glance

| Layer         | Software                                                            |
|---------------|---------------------------------------------------------------------|
| SoC bootloader| Allwinner BootROM (mask ROM)                                        |
| Stage 1       | U-Boot SPL                                                          |
| Stage 2       | U-Boot 2024.04 (custom devicetree + env)                            |
| Kernel        | Linux 6.x with custom DTS and a handful of patches                  |
| Rootfs        | Buildroot 2026.02.x, UBIFS, musl libc                               |
| Recovery      | Initramfs built from the `mds_network_player_fota` Buildroot config |
| Wi-Fi / BLE   | ESP-Hosted-NG on the ESP32-C3                                       |
| Audio         | `sun4i-spdif` ALSA driver, SPDIF output                             |

## Sections

- [Architecture](/software/architecture) — how the bits fit together
- [Boot flow](/software/boot-flow) — step-by-step from BootROM to userspace
- [FOTA strategy](/software/fota) — A/B updates and the recovery path
