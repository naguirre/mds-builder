+++
title = "Hardware"
description = "Hardware design of the Manufacture du Son network player"
sort_by = "weight"
weight = 1
template = "section.html"
page_template = "page.html"
+++

# Hardware

The Manufacture du Son network player is a custom-designed board built around two main chips:

- An **Allwinner f1c200s** ARM926EJ-S SoC, which runs Linux and handles audio output, USB and storage.
- An **Espressif ESP32-C3** companion chip that provides Wi-Fi (2.4 GHz, b/g/n) and Bluetooth Low Energy 5.0 connectivity through the [ESP-Hosted](https://github.com/espressif/esp-hosted) framework.

Audio is routed out over **SPDIF** (digital), making the board well suited to drive an external DAC. A USB-C connector provides power and acts as a USB OTG port for both flashing (FEL mode) and gadget networking with the host.

## Sections

- [Specifications](/hardware/specifications) — full bill of features and pinout-relevant info
- [Partitioning](/hardware/partitioning) — SPI NAND layout used by U-Boot and Linux
- [Board design](/hardware/design) — KiCad sources, schematics, PCB versions and fabrication outputs

![Player Top](/images/network_player_top.png)

![Player Bottom](/images/network_player_bottom.png)
