+++
title = "FOTA Strategy"
description = "Over-the-air firmware updates with a recovery initramfs"
weight = 3
+++

# FOTA Strategy

Firmware Over-The-Air (FOTA) is built around a **dedicated recovery image** plus a **scratch partition**, all hosted on the SPI NAND.

See [SPI NAND Partitioning](@/hardware/partitioning.md) for the layout reference.

## The two Buildroot configurations

| Configuration                          | Output                       | Purpose                                                  |
|----------------------------------------|------------------------------|----------------------------------------------------------|
| `mds_network_player_fota_defconfig`    | `uImage` + initramfs + DTB   | Recovery system stored in the `fota` partition           |
| `mds_network_player_defconfig`         | `uImage`, `rootfs.ubifs`     | Regular system stored in the `rootfs` partition          |

The FOTA system is intentionally **minimal**: an initramfs with the tools and shell scripts needed to flash a new rootfs and reboot — nothing else.

## Boot decision

On power-up, U-Boot loads:

1. `uImage` (kernel) — taken from the `fota` partition.
2. The device tree from `fota`.
3. The kernel command line points the root at `ubi0:rootfs` (the main rootfs in the `rootfs` partition).

The kernel attaches both UBI volumes. The init that runs first is the **FOTA initramfs**:

- If `/data/.run.ota` (a marker file) is found in the `data` partition, the FOTA script applies the new rootfs from `data/rootfs.ubifs` to the `rootfs` partition, then reboots.
- Otherwise it `switch_root`s into the main `rootfs` and Linux boots as usual.

A typical U-Boot log:

```text
** File not found .run.ota **
No OTA update found
Loading file '/boot/uImage' to addr 0x80000000...
Loading file '/boot/suniv-f1c200s-...dtb' to addr 0x80fe0000...
## Booting kernel from Legacy Image at 80000000 ...
```

## First-time setup (bootstrap)

After the very first bootstrap (see [Bootstrap](@/flashing/bootstrap.md)), all UBI volumes are still empty. They have to be created and populated:

```bash
# 1. Format each NAND partition as UBI
ubiformat /dev/mtd1
ubiformat /dev/mtd2
ubiformat /dev/mtd3

# 2. Attach UBI to each partition
ubiattach -p /dev/mtd1
ubiattach -p /dev/mtd2
ubiattach -p /dev/mtd3

# 3. Create the volumes (one per partition, taking the full space)
ubimkvol /dev/ubi0 -N fota   -m
ubimkvol /dev/ubi1 -N rootfs -m
ubimkvol /dev/ubi2 -N data   -m

# 4. Mount and populate
mkdir -p /mnt/fota /mnt/rootfs /mnt/data
mount -t ubifs /dev/ubi0_0 /mnt/fota
mount -t ubifs /dev/ubi1_0 /mnt/rootfs
mount -t ubifs /dev/ubi2_0 /mnt/data
```

From the host, copy the recovery image and the rootfs into place:

```bash
# Recovery (fota) — kernel + DTB + env
scp -O out/fota/uImage                                              mds:/mnt/fota/uImage
scp -O out/fota/uboot.env                                           mds:/mnt/fota/uboot.env
scp -O out/fota/suniv-f1c200s-mds-network-streamer-v1.0.dtb         mds:/mnt/fota/

# Main rootfs (staged in data, then flashed into rootfs volume)
scp -O out/network_player/rootfs.ubifs                              mds:/mnt/data/rootfs.ubifs
```

Apply the rootfs to its UBI volume:

```bash
ubiupdatevol /dev/ubi1_0 /mnt/data/rootfs.ubifs
```

After this the board can boot end-to-end from NAND with the recovery in `fota` and the system in `rootfs`.

## Open questions / TODO

The following items are tracked but not yet implemented:

- Persist the U-Boot environment back into NAND (currently `Loading Environment from nowhere`).
- Promote the layout to a proper **A/B** scheme with `rootfs-a` / `rootfs-b` volumes and atomic switch.
