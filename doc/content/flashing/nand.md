+++
title = "Flashing SPI NAND"
description = "Writing the bootloader and rootfs onto the 128 MiB SPI NAND"
weight = 2
+++

# Flashing SPI NAND

Once you have a working system on the board (either the [bootstrap image](@/flashing/bootstrap.md) or a previously flashed firmware), you can write a fresh bootloader and rootfs to the SPI NAND.

> For a fresh board, the [bootstrap](@/flashing/bootstrap.md) flow (`./bootstrap.sh` or the
> `make bootstrap-bundle` `.run`) runs every step below automatically over SSH. The manual
> procedure here is kept as reference and for one-off re-flashes.

## On the host: copy artifacts to the board

After `make build MACHINE=network_player`, the relevant output files live in `out/network_player/`:

- `spi-nand.bin` — `mknandboot.sh`-processed `u-boot-with-spl.bin`, ready for `mtd0`
- `rootfs.ubifs` — UBIFS image for the `rootfs` volume

Copy them to the running system, using the `data` partition as scratch:

```bash
scp -O out/network_player/rootfs.ubifs root@192.168.2.2:/mnt/data
scp -O out/network_player/spi-nand.bin root@192.168.2.2:/mnt/data
```

(Make sure `/mnt/data` is mounted from `ubi2_0` — see [FOTA strategy](@/software/fota.md) for the one-time UBI setup.)

## On the board: erase, format, write

If this is the very first time you touch the NAND from Linux, erase the raw MTD partitions:

```bash
flash_erase /dev/mtd0 0 0
flash_erase /dev/mtd1 0 0
flash_erase /dev/mtd2 0 0
flash_erase /dev/mtd3 0 0
```

Then format the UBI partitions:

```bash
ubiformat /dev/mtd1
ubiformat /dev/mtd2
ubiformat /dev/mtd3
```

Attach and create volumes (one-time setup, see [FOTA strategy](@/software/fota.md)):

```bash
ubiattach -p /dev/mtd1
ubiattach -p /dev/mtd2
ubiattach -p /dev/mtd3
ubimkvol /dev/ubi0 -N fota   -m
ubimkvol /dev/ubi1 -N rootfs -m
ubimkvol /dev/ubi2 -N data   -m
```

Finally, do the actual writes:

```bash
# Bootloader: raw write into mtd0
flashcp /mnt/data/spi-nand.bin /dev/mtd0

# Rootfs: applied to UBI volume ubi1_0
ubiupdatevol /dev/ubi1_0 /mnt/data/rootfs.ubifs
```

Reboot — the board should now come up from NAND with the new firmware.

## Alternative: flashing from U-Boot

For the very first flash (no usable Linux on the device yet), the bootloader can be written from U-Boot itself, after loading it into RAM through FEL:

```bash
sunxi-fel -p uboot images/u-boot-sunxi-with-spl.bin \
  write 0x80000000 images/spi-nand.bin
```

Then, on the running U-Boot console:

```text
=> mtd erase boot
=> mtd write.raw boot 0x80000000
=> reset
```

> The raw `write.raw` is important — `mtd write` would re-apply ECC/OOB on top of what is already there, mangling the image.

## Gotchas

- **LEB size**: the UBIFS image produced by Buildroot must match the LEB size of the runtime UBI device, otherwise mounting fails. See [SPI NAND Partitioning](@/hardware/partitioning.md).
- **`reset` not supported**: some U-Boot defconfigs miss the watchdog reset driver and print
  `System reset not supported on this platform`. Power-cycle in that case, then fix the defconfig.
- **`Wrong Image Type for bootm command`**: use the FIT image (see `image.its` in the board files).
