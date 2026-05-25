+++
title = "U-Boot Development"
description = "Iterate on the bootloader, the DTS and the environment"
weight = 2
+++

# U-Boot Development

The bootloader uses U-Boot 2024.04 with a custom defconfig and devicetree. All the moving parts live under `mds_external/board/mds_network_player/`.

## Rebuild

```bash
make build-uboot-rebuild
```

Produced artifacts (`build/output/<machine>/images/`):

- `u-boot-sunxi-with-spl.bin` — SPL + U-Boot, raw image
- `spi-nand.bin` — same, post-processed by `mknandboot.sh` for SPI NAND boot

## Edit the configuration

```bash
make build-uboot-menuconfig
make build-uboot-savedefconfig
cp build/output/network_player/build/uboot-*/defconfig \
   mds_external/board/mds_network_player/u-boot_defconfig
```

## Devicetree and patches

- `u-boot_devicetree.dts` — board DTS injected into U-Boot at configure time.
- `uboot-patches/` — patches applied on top of upstream U-Boot, in lexicographic order.

After editing either, force a clean rebuild:

```bash
make build-uboot-dirclean
make build-uboot
```

## U-Boot environment

`uboot.env` (regular) and `uboot.bootstrap.env` (bootstrap image) describe the script U-Boot evaluates at boot.

Common things you may want to add there:

- Probe `/run.ota` from the `fota` partition to trigger a recovery path.
- Adjust the kernel command line (`ubi.mtd=`, `console=`, `rootfstype=`).
- Pick `uImage` from `fota` vs `rootfs`.

> **Heads up**: today the environment is loaded from "nowhere" (boot log: `Loading Environment from nowhere... OK`). Persisting the env back to a dedicated MTD region is on the TODO list — until then the script must be baked at build time.

## SPI NAND boot machinery

Two scripts handle the SPL/U-Boot relocation needed for SPI NAND boot on the f1c200s:

- `mknandboot.sh` — splits and re-packs `u-boot-with-spl.bin` so the BootROM can load the SPL and the SPL can find U-Boot at the right offset.
- `f1c100_uboot_spinand.sh` — older companion script kept for reference.

Background and references:

- [OpenWrt SPI NAND image generator (DolphinPi)](https://github.com/bamkrs/openwrt/blob/dolphinpi-spinand/target/linux/sunxi/image/gen_sunxi_spinand_onlyboot_img.sh)
- [TiNredmc u-boot SPI NAND fork](https://github.com/TiNredmc/u-boot/blob/v2020/f1c100_uboot_spinand.sh)
- [Lichee Pi Nano + W25N01GV SPI NAND guide](https://tinlethax.wordpress.com/2021/04/11/lichee-pi-nano-with-w25n01gv-support-complete-guide/)
- [Mailing list patch series — SPI NAND boot for sunxi](https://patchwork.ozlabs.org/project/uboot/cover/20221014030520.3067228-1-uwu@icenowy.me/)

## FIT image

A FIT image (`image.its`) is used because plain legacy `bootm` was failing with `Wrong Image Type for bootm command`. The FIT bundles the kernel, the DTB and (for the FOTA flow) the initramfs.
