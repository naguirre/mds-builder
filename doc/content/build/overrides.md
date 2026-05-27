+++
title = "Package overrides"
description = "Point Buildroot at a local source tree instead of fetching the upstream tarball"
weight = 4
+++

# Package overrides

Buildroot has a built-in mechanism — `<PACKAGE>_OVERRIDE_SRCDIR` — that
tells it to `rsync` a package from a local directory instead of
downloading the upstream tarball. The MDS tree wires this up through two
files in `mds_external/`.

## `overrides.mk` (tracked)

`mds_external/overrides.mk` is the versioned override file applied by all
defconfigs (`BR2_PACKAGE_OVERRIDE_FILE`). It contains the overrides that
must be active in CI and on every machine. Today this is just one entry:

```make
ESP_HOSTED_OVERRIDE_SRCDIR = $(TOPDIR)/../../src/esp-hosted
```

`src/esp-hosted/` is a git submodule pinned to the fork that carries the
two patches needed for the MDS board (`SPI_MODE = 1`, `register_hs_disable_pin`,
…). The CI checks out submodules recursively so this just works.

## `local.mk` (gitignored)

`overrides.mk` ends with:

```make
-include $(BR2_EXTERNAL_MDS_PATH)/local.mk
```

so any `local.mk` you drop next to it is picked up automatically. This is
the place for **personal, development-only** overrides — typical example:
a kernel checkout you iterate on outside Buildroot. See
[`local.mk.example`](https://github.com/naguirre/mds-builder/blob/main/mds_external/local.mk.example)
for the template.

## Available variables

Any Buildroot package can be overridden by setting
`<UPPERCASED_PACKAGE_NAME>_OVERRIDE_SRCDIR`. Examples:

| Package | Variable |
|---|---|
| Linux kernel | `LINUX_OVERRIDE_SRCDIR` |
| U-Boot | `UBOOT_OVERRIDE_SRCDIR` |
| esp-hosted | `ESP_HOSTED_OVERRIDE_SRCDIR` |
| busybox | `BUSYBOX_OVERRIDE_SRCDIR` |

The path is relative to Buildroot's `$(TOPDIR)`. In this repo Buildroot
lives under `build/buildroot-2026.02.1/`, so `$(TOPDIR)/../../src/foo`
resolves to `<repo>/src/foo`.

See the [Buildroot manual on override
files](https://buildroot.org/downloads/manual/manual.html#_using_buildroot_during_development)
for the full reference.
