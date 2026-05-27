+++
title = "ESP-Hosted firmware"
description = "Rebuild and flash the ESP32-C3 companion firmware, and basic runtime commands"
weight = 4
+++

# ESP-Hosted firmware

The Wi-Fi and BLE stack runs on the ESP32-C3 and talks to the f1c200s over SPI through [ESP-Hosted](https://github.com/espressif/esp-hosted). The host-side driver (`esp32_spi` / `esp-hosted-ng`) is built by Buildroot; the ESP32-C3 firmware lives under `src/esp-hosted/esp_hosted_ng/esp/esp_driver/`.

## Rebuilding the ESP32-C3 firmware

From the repository root:

```sh
cd src/esp-hosted/esp_hosted_ng/esp/esp_driver
cmake .                          # fetches esp-idf as a submodule
cd esp-idf && . ./export.sh      # activate the ESP-IDF toolchain
cd ../network_adapter
idf.py set-target esp32-c3
idf.py build
```

The resulting binary is then flashed to the ESP32-C3 over its UART/USB programming interface.

## Loading the host driver

The `esp32_spi` module is loaded at runtime against the host SPI bus. The reset GPIO and SPI clock speed are passed as module parameters:

```sh
modprobe esp32_spi resetpin=97 clockspeed=1
```

Once the link is up, a virtual interface appears:

```sh
ip link show espsta0
ip link set dev espsta0 up
iw espsta0 scan
```

`espsta0` is a standard wireless netdev; configure it via `iw`, `wpa_supplicant`, or `iwd` as usual.
