+++
title = "ESP32-C3 Firmware"
description = "Updating the ESP-Hosted-NG firmware on the companion chip"
weight = 3
+++

# ESP32-C3 Firmware

The Wi-Fi and Bluetooth stack runs on the ESP32-C3 companion chip via [ESP-Hosted-NG](https://github.com/espressif/esp-hosted). When you change `network_adapter` (the ESP-side firmware), you need to rebuild it and flash it onto the ESP32-C3.

## Rebuild

The sources are vendored under `src/esp-hosted/` in this repository (mirrors of [espressif/esp-hosted](https://github.com/espressif/esp-hosted)).

```bash
# 1. Enter the ESP-IDF driver directory
cd src/esp-hosted/esp_hosted_ng/esp/esp_driver

# 2. Bootstrap the environment — clones ESP-IDF at the pinned commit (from .env),
#    applies the ROM patch, initializes submodules, and copies the custom Wi-Fi
#    libraries from lib/ into esp-idf/components/esp_wifi/lib/.
./setup.sh

# 3. Activate the ESP-IDF environment for this shell
. ./esp-idf/export.sh

# 4. Configure target and build
cd network_adapter
rm -f sdkconfig    # force regeneration from sdkconfig.defaults.* after any change
idf.py set-target esp32c3
idf.py build
```

The produced binaries live under `network_adapter/build/` (notably `network_adapter.bin`, `bootloader/bootloader.bin`, and `partition_table/partition-table.bin`).

### Verifying your sdkconfig changes are applied

If you edited `sdkconfig.defaults.esp32c3` (e.g. to enable `CONFIG_ESP_SPI_DEASSERT_HS_ON_CS=y`), confirm the option made it into the generated `sdkconfig` after `set-target`:

```bash
grep DEASSERT_HS_ON_CS sdkconfig
# Expected: CONFIG_ESP_SPI_DEASSERT_HS_ON_CS=y
```

If the option is missing or `not set`, an old `sdkconfig` was reused — remove it and re-run `set-target`.

### Troubleshooting: linker errors on `esp_wifi_*` / `ieee80211_*` symbols

If the link step fails with `undefined reference to esp_wifi_get_eb_data`, `ieee80211_add_node`, `esp_wifi_send_auth_internal`, etc., the stock ESP-IDF Wi-Fi libraries are being linked instead of the ESP-Hosted-NG custom ones. This happens when something (a `git submodule update`, an `idf.py` clean, or `setup.sh -u` exiting before the copy step) restored the upstream libraries inside `esp-idf/components/esp_wifi/lib/`.

Reinstall the custom libraries:

```bash
cd src/esp-hosted/esp_hosted_ng/esp/esp_driver
cp -r lib/* esp-idf/components/esp_wifi/lib/

# Sanity check — both files must match
md5sum lib/esp32c3/libnet80211.a esp-idf/components/esp_wifi/lib/esp32c3/libnet80211.a
```

Then rebuild from `network_adapter/`.

## Flashing

By default, the ESP32-C3 boots into DFU/USB mode rather than expecting UART downloads. To force serial download mode you have to pull **GPIO8** low while resetting the chip — the dedicated `ESP_BOOT` button on the board does exactly that.

A helper script is provided under `mds_external/board/mds_network_player/`:

```bash
sh mds_external/board/mds_network_player/flash_esp32.sh
```

It wraps `esptool.py` with the right port and offsets. Adjust the port inside the script if your USB-serial adapter is not the one assumed.

## Communication sanity check

After flashing, you can verify the ESP↔host link with a USB-UART adapter on the inter-chip UART: pressing the ESP reset should print a banner. Once the kernel-side `esp-hosted-ng` driver is loaded, the Wi-Fi interface should appear as `wlan0` and standard `iw` / `wpa_supplicant` workflows apply.
