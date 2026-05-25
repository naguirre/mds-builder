+++
title = "Debugging"
description = "Serial console, USB gadget networking, common errors"
weight = 3
+++

# Debugging

## Serial console

The primary console is **UART0** on the f1c200s, exposed on the board's UART header. Baud rate is **115200 8N1**.

Linux:

```bash
picocom -b 115200 /dev/ttyUSB0
```

macOS:

```bash
picocom -b 115200 /dev/tty.usbserial-FTA02VH8
```

The console shows U-Boot output and the Linux boot log, and gives you a login prompt
(`root` / `root`).

## USB Ethernet gadget

`g_ether` is configured in the rootfs, so as soon as Linux is up the device exposes itself as a USB Ethernet adapter:

- Device address: **`192.168.2.2`**
- Host address: assign `192.168.2.1/24` to the corresponding host interface

```bash
ssh root@192.168.2.2
```

The MAC address is announced at boot; for example:

```text
g_ether gadget.0: HOST MAC 22:84:d6:6a:6c:8f
g_ether gadget.0: MAC 5a:6c:c6:09:0f:dd
```

If the gadget never enumerates, look for this in the kernel log:

```text
UDC core: g_ether: couldn't find an available UDC
```

It usually means the USB OTG controller is held by something else (musb host mode, etc.) — check the DTS and `usb_phy_generic`.

## Mass storage gadget

There is an experimental setup using `g_mass_storage`. Status: not currently functional but kept as a reference.

```bash
modprobe g_mass_storage iSerialNumber=123456 file=/mnt/fat32.part stall=0 removable=1
losetup /dev/loop0 /mnt/fat32.part
```

## Common errors

| Symptom                                                                | Cause / Fix                                                                                                  |
|------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| `System reset not supported on this platform` in U-Boot                | Watchdog reset support missing in U-Boot defconfig — enable it and rebuild.                                  |
| `Wrong Image Type for bootm command`                                   | Use the FIT image (`image.its` / `*.itb`) instead of legacy uImage.                                          |
| `UBIFS error: LEB size mismatch: 129024 in superblock, 126976 real`    | Buildroot UBIFS LEB size differs from the runtime UBI device. See [SPI NAND Partitioning](/hardware/partitioning). |
| `ubi: mtd1 is already attached to ubi0`                                | The volume is still attached from a previous attempt. `ubidetach -p /dev/mtd1` first.                        |
| `failed to load regulatory.db`                                         | Cosmetic — the Wi-Fi regulatory DB blob is not shipped; safe to ignore.                                      |
| `SPI driver fb_ili9340 has no spi_device_id for ilitek,ili9340`        | Optional LCD probe; cosmetic if you do not use the display.                                                  |
| `Failed to request TX DMA channel` on `sun6i-spi`                      | f1c200s DMA is not supported in mainline — SPI falls back to PIO automatically.                              |

## Boot time

Measured 16/06/2024: cold boot to login ≈ **24 s**, of which:

- ~1 s: SPL + U-Boot
- ~7 s: U-Boot kernel/DTB loading
- ~16 s: kernel + UBI attach + UBIFS recovery + userspace

The dominating chunks are UBI scan (~0.8 s) and `uImage` load from UBIFS (~3.7 s). Improvements likely come from `fastmap` and from trimming the kernel image.

## PS1

A coloured prompt that has proved useful in long debug sessions:

```bash
PS1='\[\e[0;31m\]\u\[\e[m\] \[\e[0;32m\]\h\[\e[m\]@\[\e[0;34m\]\w\[\e[m\]\$ '
```
