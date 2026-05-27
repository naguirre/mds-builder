+++
title = "Manufacture du Son"
description = "Documentation for an open-source network audio player based on the Allwinner f1c200s and ESP32-C3."
sort_by = "weight"
+++

The **Manufacture du Son** network player is a custom board built around an
Allwinner **f1c200s** SoC running Linux and an **ESP32-C3** companion chip
providing Wi-Fi and BLE. Audio is routed out over SPDIF.

This site documents how to build the firmware, flash it onto a board, and
develop on top of it.

## Where to go next

{% cards() %}
{{ card(title="Hardware", description="Board overview, specifications and PCB design files", href="/hardware") }}
{{ card(title="Software", description="Boot flow, system architecture and FOTA updates", href="/software") }}
{{ card(title="Build", description="Buildroot defconfigs, machines and prerequisites", href="/build") }}
{{ card(title="Flashing", description="Getting images onto the SPI NAND", href="/flashing") }}
{{ card(title="Development", description="Day-to-day work on the kernel, U-Boot and ESP-Hosted firmware", href="/development") }}
{% end %}

## Quick start

```sh
make build              # build the network player firmware natively
make build CONTAINER=1  # build inside the Docker container
```

Output images land in `output/images/`. See the [flashing guide](/flashing) for
the next steps.
