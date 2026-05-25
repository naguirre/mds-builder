+++
title = "Specifications"
description = "Full specifications of the network player board v1"
weight = 1
+++

# Specifications

## Compute

| Component       | Detail                                    |
|-----------------|-------------------------------------------|
| SoC             | Allwinner f1c200s (ARM926EJ-S, ARMv5TE)   |
| RAM             | 64 MiB (integrated in package)            |
| Storage         | 128 MiB SPI NAND (Winbond)                |
| Wireless MCU    | Espressif ESP32-C3                        |

## Connectivity

- Wi-Fi 2.4 GHz b/g/n (via ESP32-C3 and ESP-Hosted)
- Bluetooth Low Energy 5.0 (via ESP32-C3)
- USB 2.0 OTG on USB-C
- 40-pin extension header

## Audio

- SPDIF digital output (driven by the `sun4i-spdif` Linux driver)
- No on-board DAC — pair with an external SPDIF DAC

## Power & I/O

- 5 V power input over USB-C
- Internal rails: 3.3 V, 2.5 V, 1.1 V (validated on bring-up)
- 1 user-controllable LED
- 3 buttons:
  - reset for the f1c200s
  - reset for the ESP32-C3
  - boot-select to put the f1c200s into USB FEL (bootstrap) mode

## Identification

In the boot logs the board reports:

```text
Model: La Manufacture du Son - Network Streamer
CPU:   Allwinner F Series (SUNIV)
```

The Linux device tree machine string is `MDS Network Streamer v1.0`.

## SoC notes

The f1c200s is part of the Allwinner *suniv* family (sun3iw1). Some peripherals — notably I²S DMA — are not mainline yet. The board currently uses **SPDIF only** for audio.

References:

- [linux-sunxi wiki: F1C100s / F1C200s](https://linux-sunxi.org/Allwinner_SoC_Family#F-series_.28suniv.29)
- DMA / audio codec patches discussion: [linux-sunxi.narkive.com](https://linux-sunxi.narkive.com/3zRXUcrE/rfc-patch-00-10-add-support-for-dma-and-audio-codec-of-f1c100s)
