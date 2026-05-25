+++
template = "landing.html"
title = "Manufacture du Son"

[extra]
section_order = ["hero", "features", "easy_command"]

[extra.hero]
title = "Manufacture du Son"
badge = "Network Audio Player"
description = "Music Soothes the Savage Breast — an open-source embedded audio streaming platform built around the Allwinner f1c200s and the ESP32-C3."
gradient_opacity = 30
image_opacity = 25
cta_buttons = [
    { text = "Get Started",  url = "/build",    style = "primary" },
    { text = "Hardware",     url = "/hardware", style = "secondary" },
]

[extra.features_section]
title = "Project Highlights"
description = "From schematics to firmware — everything you need to build, flash and hack the device"

[[extra.features_section.features]]
title = "Custom Hardware"
desc = "Allwinner f1c200s SoC, ESP32-C3 for Wi-Fi/BLE, SPDIF output, 40-pin headers, USB-C. KiCad sources available."
icon = "microchip"

[[extra.features_section.features]]
title = "Buildroot-based"
desc = "Reproducible firmware built with Buildroot 2026.02.x and a BR2_EXTERNAL tree for boards, packages and overlays."
icon = "cube"

[[extra.features_section.features]]
title = "A/B FOTA Layout"
desc = "5-partition SPI NAND layout with a recovery initramfs and dual rootfs slots for safe over-the-air updates."
icon = "rotate"

[[extra.features_section.features]]
title = "Containerised Builds"
desc = "Optional Docker workflow (CONTAINER=1) gives you a reproducible Ubuntu 24.04 toolchain on any host."
icon = "docker"

[[extra.features_section.features]]
title = "Multi-Machine"
desc = "Configurations for the network player, the bootstrap image, the FOTA recovery, V851s Lizard, and several Raspberry Pi boards."
icon = "layer-group"

[[extra.features_section.features]]
title = "Hackable"
desc = "U-Boot + mainline Linux 6.x, custom device tree, SPDIF audio, USB gadget networking, ESP-Hosted Wi-Fi."
icon = "wrench"

[extra.easy_command_section]
title = "Quick Start"
description = "Build the default network player firmware"

[[extra.easy_command_section.tabs]]
name = "Native"
command = "make build"

[[extra.easy_command_section.tabs]]
name = "Docker"
command = "make build CONTAINER=1"

[[extra.easy_command_section.tabs]]
name = "Bootstrap"
command = "make build MACHINE=mds_network_player_bootstrap"

[[extra.easy_command_section.tabs]]
name = "More"
link = "/build"
+++
