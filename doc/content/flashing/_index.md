+++
title = "Flashing"
description = "Bringing up the board and writing firmware to SPI NAND"
sort_by = "weight"
weight = 4
template = "section.html"
page_template = "page.html"
+++

# Flashing

Two distinct workflows are involved in getting firmware onto the device:

1. **Bootstrap** — load a temporary, RAM-only image over USB FEL the very first time the board sees power, so you can talk to it through a USB Ethernet gadget and a serial console.
2. **Flashing** — from that running bootstrap (or from any working system), write the SPL/U-Boot to `mtd0` and the rootfs to the `rootfs` UBI volume.

Each workflow has its own page:

- [Bootstrap](@/flashing/bootstrap.md) — initial load via `sunxi-fel`
- [SPI NAND flashing](@/flashing/nand.md) — `flashcp` for the bootloader, `ubiupdatevol` for the rootfs
- [ESP32-C3 flashing](@/flashing/esp32.md) — companion firmware

> **Cable**: a single USB-C cable is enough for both flow steps — it provides power, USB FEL access, and the USB gadget Ethernet link.
