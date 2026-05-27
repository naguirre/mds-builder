+++
title = "Build"
description = "Building the firmware from source"
sort_by = "weight"
weight = 3
template = "section.html"
page_template = "page.html"
+++

# Build

The whole firmware is built from this repository. The top-level [Makefile](https://github.com/naguirre/mds-builder/blob/main/Makefile) wraps Buildroot and exposes a small set of targets that work either natively on a Linux host or inside a Docker container.

## TL;DR

```bash
git clone https://github.com/naguirre/mds-builder.git
cd mds-builder
make build                                 # default: MACHINE=network_player
```

or, fully containerised:

```bash
make build CONTAINER=1
```

## Sections

- [Prerequisites](/build/prerequisites) — host packages, Docker option
- [Targets](/build/targets) — what each `make` target does
- [Machines](/build/machines) — defconfigs and what they produce
- [Buildroot external tree](/build/buildroot) — how `BR2_EXTERNAL` is organised
- [Package overrides](/build/overrides) — replace a package source with a local checkout
