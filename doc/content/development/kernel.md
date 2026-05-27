+++
title = "Kernel Development"
description = "Iterate on the Linux kernel and out-of-tree modules"
weight = 1
+++

# Kernel Development

The kernel is built by Buildroot like any other package. Iterating on it without a full rebuild is the most common loop.

## Develop the kernel out-of-tree

For larger kernel changes it is more convenient to keep a separate Linux
checkout and have Buildroot pick it up instead of the tarball it would
normally download.

1. Clone the kernel next to the Buildroot tree:

   ```sh
   git clone https://github.com/torvalds/linux.git build/linux
   git -C build/linux checkout v6.7
   ```

2. Tell Buildroot to use it via a local override file. Create
   `mds_external/local.mk` (gitignored, see `local.mk.example`):

   ```make
   LINUX_OVERRIDE_SRCDIR = $(TOPDIR)/../../build/linux
   ```

3. Re-run `make build`. Buildroot will rsync from `build/linux/` instead
   of fetching the upstream tarball.

The same pattern works for any package — set
`<PACKAGE>_OVERRIDE_SRCDIR` in `local.mk`. See the
[overrides reference](@/build/overrides.md) for the full mechanism.

## Build only the kernel

```bash
make build-linux-rebuild
```

This runs `make linux-rebuild` inside the Buildroot output for `MACHINE`. Outputs of interest:

- `build/output/<machine>/images/uImage` — the kernel image used by U-Boot
- `build/output/<machine>/target/lib/modules/<ver>/` — built-as-modules drivers staged for the rootfs

## Copy to a running target

A running board with USB Ethernet gadget shows up at `192.168.2.2`. Push the new kernel:

```bash
scp -O /workspace/build/output/network_player/images/uImage \
    root@192.168.2.2:/boot
```

Push a single module (example: SPDIF driver):

```bash
scp -O \
  /workspace/build/output/network_player/target/lib/modules/6.7.2/kernel/sound/soc/sunxi/sun4i-spdif.ko \
  root@192.168.2.2:/usr/lib/modules/6.7.2/kernel/sound/soc/sunxi/sun4i-spdif.ko
```

> Replace `6.7.2` with the actual kernel version of your build. Use `uname -r` on the device to check.

After copying, reload the module or reboot.

## Change the kernel config

```bash
make build-linux-menuconfig
make build-linux-savedefconfig
cp build/output/network_player/build/linux-*/defconfig \
   mds_external/board/mds_network_player/kernel_defconfig
```

The defconfig file is what ships in version control — your `menuconfig` changes only persist when copied back into `kernel_defconfig`.

## Kernel patches

Patches under `mds_external/board/mds_network_player/linux-patches/` are applied in lexicographic order by Buildroot before the build. Add a new patch file there, give it a numeric prefix (e.g. `0002-fix-spdif.patch`), and trigger a clean kernel rebuild:

```bash
make build-linux-dirclean
make build-linux
```

## Useful peripherals notes

- **GPIO numbering**: the f1c200s pinctrl uses banks A..E. The Linux GPIO number for `PD6` (the user button on the Respeaker 2 mics HAT) is
  `4 * 32 - 1 + 6 = 102`. Validate with:

  ```bash
  gpio-event-mon -n gpiochip0 -o 102 -r -f -b 10000
  ```

- **DMA**: not supported on f1c200s in mainline. Out-of-tree patches exist; SPI and audio peripherals currently run without DMA acceleration on this board.

- **I²S audio**: the f1c200s I²S driver is not in mainline. SPDIF is used instead.
