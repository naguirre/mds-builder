+++
title = "Bootstrap"
description = "Loading the initial RAM-only image via USB FEL"
weight = 1
+++

# Bootstrap

The bootstrap workflow runs a temporary Linux system entirely from RAM, just long enough to write the real firmware onto the SPI NAND.

## Prerequisites

- [`sunxi-fel`](https://github.com/linux-sunxi/sunxi-tools) cloned/built somewhere reachable
  (the project assumes `~/Dev/sunxi-tools/sunxi-fel`).
- A USB-C cable between host and board.
- A USB-to-serial adapter wired to the board's UART, accessible as e.g.
  `/dev/ttyUSB0` (Linux) or `/dev/tty.usbserial-FTA02VH8` (macOS).
- A terminal program — `picocom`, `minicom` or similar.

## Step 1: Build the bootstrap image

```bash
make build MACHINE=mds_network_player_bootstrap
```

The output is dropped into `out/network_player_bootstrap/`:

- `u-boot-sunxi-with-spl.bin`
- `uImage`
- `rootfs.cpio.uboot`
- `suniv-f1c200s-mds-network-streamer-v1.0.dtb`

## Step 2: Put the board into FEL mode

1. Hold the `BOOT` button.
2. Press and release the f1c200s reset button.
3. Release the `BOOT` button.

The board should now appear on the host as a USB device with the Allwinner FEL VID/PID. Verify with:

```bash
sunxi-fel ver
```

## Step 3: Push the image over USB

The [`bootstrap.sh`](https://github.com/naguirre/mds-builder/blob/main/bootstrap.sh) script wraps the `sunxi-fel` calls and the U-Boot interaction:

```bash
./bootstrap.sh /dev/tty.usbserial-FTA02VH8
```

What it does:

1. Calls `sunxi-fel` with `write-with-progress` four times to push:
   - the SPL+U-Boot at `0x80000000`,
   - the kernel `uImage` at `0x80000000` (overwritten — SPL puts U-Boot somewhere safe),
   - the `rootfs.cpio.uboot` at `0x80500000`,
   - the DTB at `0x80FE0000`.
2. Sends a few empty lines on the serial port to interrupt U-Boot autoboot.
3. Sends `bootm 0x80000000 0x80500000 0x80FE0000` to launch the in-RAM image.

## Step 4: Talk to the running bootstrap

Open a serial console:

```bash
picocom -b 115200 /dev/tty.usbserial-FTA02VH8
```

You should land on a Linux login prompt. Default credentials: **`root` / `root`**.

The bootstrap also brings up the USB Ethernet gadget. Once the host enumerates the new interface (assign it `192.168.2.1/24`), you can SSH in:

```bash
ssh root@192.168.2.2
```

From here you are ready to actually write the firmware — head over to
[SPI NAND flashing](/flashing/nand).
