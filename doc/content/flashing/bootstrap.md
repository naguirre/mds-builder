+++
title = "Bootstrap"
description = "Loading the initial RAM-only image via USB FEL and provisioning the NAND"
weight = 1
+++

# Bootstrap

The bootstrap workflow runs a temporary Linux system entirely from RAM, just long enough to write the real firmware onto the SPI NAND. The whole flow — FEL push, autoboot, and NAND provisioning over SSH — is driven by [`bootstrap.sh`](https://github.com/naguirre/mds-builder/blob/main/bootstrap.sh).

## Prerequisites

- [`sunxi-fel`](https://github.com/linux-sunxi/sunxi-tools) cloned/built somewhere reachable
  (the project assumes `~/Dev/sunxi-tools/sunxi-fel`; override with `SUNXI_FEL=...`).
- `sshpass` installed on the host — the board's Dropbear only does password auth (`root`/`root`),
  and the script runs every `ssh`/`scp` non-interactively. Override the password with `SSH_PASS=...`.
- A USB-C cable between host and board.
- The host USB-Ethernet interface configured as `192.168.2.1/24` (the board comes up as `192.168.2.2`).
  The script does not bring this up; configure it once the gadget enumerates.
- *(optional)* A USB-to-serial adapter on the board's UART (`/dev/ttyUSB0`, …) for monitoring.

## Step 1: Build the images

```bash
make build MACHINE=network_player_bootstrap   # RAM-only bootstrap image
make build MACHINE=network_player             # production firmware to flash
```

Outputs land in `out/network_player_bootstrap/` and `out/network_player/`.

## Step 2: Put the board into FEL mode

1. Hold the `BOOT` button.
2. Press and release the f1c200s reset button.
3. Release the `BOOT` button.

Verify with `sunxi-fel ver`.

## Step 3: Run the bootstrap

```bash
./bootstrap.sh /dev/ttyUSB0     # serial arg is optional (monitoring only)
```

What it does:

1. Drops the stale SSH host key for `192.168.2.2`.
2. Pushes the bootstrap image over FEL with `sunxi-fel`, using the fixed RAM layout:
   - SPL+U-Boot loaded by `sunxi-fel uboot`,
   - kernel `uImage` at `0x80000000`,
   - `rootfs.cpio.uboot` at `0x82800000`,
   - DTB at `0x83A00000`.
3. **U-Boot autoboots on its own** (`CONFIG_BOOTDELAY=1`) using the compiled-in `bootcmd`
   (`bootm ${kernel_addr} ${ramdisk_addr} ${fdt_addr}` — see `uboot.bootstrap.env`).
   The script sends **nothing** on the serial line; if a serial device is given it is only
   read, prefixed with `[serial]`, to follow the boot.
4. Waits for SSH on `root@192.168.2.2`, then provisions the NAND (see below).

### RAM layout

DRAM is `0x80000000`–`0x84000000` (64 MiB). The blocks are kept disjoint so U-Boot's
relocation never clobbers a neighbour:

| Block | Address | Offset | Budget |
|---|---|---|---|
| uImage source (copied by `bootm` to `0x82000000`) | `0x80000000` | +0 | 6 MiB |
| kernel destination (`UIMAGE_LOADADDR`) | `0x82000000` | +32 MiB | 6 MiB |
| initramfs `rootfs.cpio.uboot` | `0x82800000` | +40 MiB | 16 MiB |
| DTB | `0x83A00000` | +58 MiB | 128 KiB |
| `initrd_high` / `fdt_high` ceiling | `0x83C00000` | +60 MiB | — |

Nothing sits below `0x82000000` at runtime, which avoids both the kernel-reserved low zone
(otherwise the initrd is dropped with `overlaps in-use memory region`) and the DTB being
overwritten by initrd relocation. The build warns if `uImage` or `rootfs.cpio` outgrows its
budget (see `post-images.sh`).

## Step 4: NAND provisioning

Once SSH is up, `bootstrap.sh` provisions the NAND automatically (commands run over SSH):

1. `scp` `spi-nand.bin` and `rootfs.ubifs` to `/tmp` on the board.
2. `flash_erase` `mtd0`–`mtd3`.
3. `ubiformat` + `ubiattach` `mtd1`–`mtd3`, then `ubimkvol` the `fota` / `rootfs` / `data` volumes.
4. `flashcp spi-nand.bin /dev/mtd0` and `ubiupdatevol /dev/ubi1_0 rootfs.ubifs`.
5. `reboot`.

After reboot the board comes up from NAND with the production firmware. If it does not reset
(some U-Boot defconfigs miss the watchdog reset driver), power-cycle it.

The manual equivalent of these steps is documented in [SPI NAND flashing](@/flashing/nand.md).

## One-command bundle

`make bootstrap-bundle` builds both images and packs everything (scripts + artifacts) into a
self-extracting [`makeself`](https://makeself.io/) archive:

```bash
make bootstrap-bundle              # produces bootstrap-<version>.run
./bootstrap-<version>.run -- /dev/ttyUSB0
```

The `.run` extracts itself and executes the full bootstrap + provisioning flow end to end.
