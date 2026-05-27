# Manufacture du Son

Open-source network audio player firmware. The board is built around an Allwinner **F1C200s** SoC running Linux and an **ESP32-C3** companion chip handling Wi-Fi and BLE. Audio is routed out over SPDIF.

📖 **Full documentation**: <https://naguirre.github.io/mds-builder/>

## Quick start

```sh
make build              # build firmware natively (Buildroot)
make build CONTAINER=1  # build inside the Docker container
```

Output images land in `output/images/`. See the [flashing guide](https://naguirre.github.io/mds-builder/flashing/) for getting them onto a board.

## Repository layout

- `buildroot_config/` — Buildroot defconfigs per machine
- `mds_external/` — `BR2_EXTERNAL` tree (boards, packages, overlays, FIT image)
- `mds-hardware/` — KiCad sources (see [mds-hardware/README.md](mds-hardware/README.md))
- `doc/` — Zola site, source for the published docs
- `src/esp-hosted/` — vendored ESP-Hosted sources

## Browsing the docs locally

```sh
cd doc && zola serve
```

## Hardware

The KiCad projects and PCB versions (v1, v1.1, v2) live under [`mds-hardware/`](mds-hardware/README.md). Schematics, PCB PDFs and gerbers are published alongside the documentation under `/hardware/<version>/`.

## License

- **Software** (this repository): MIT — see [LICENSE](LICENSE)
- **Hardware** (`mds-hardware/`): CERN-OHL-P v2 — see [mds-hardware/LICENSE](mds-hardware/LICENSE)
