#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
OUT_DIR="${BUILD_DIR}/../images/"

# Warn (never fail) when an image outgrows its slot in the FEL RAM layout
# (see uboot.bootstrap.env): the kernel must fit below the initramfs at
# +40 MiB, and the initramfs below the DTB at +58 MiB.
check_image_sizes() {
    local dir="$1"
    local kernel_max=$((6 * 1024 * 1024))     # uImage budget: 6 MiB
    local initramfs_max=$((16 * 1024 * 1024))  # rootfs.cpio budget: 16 MiB
    local f size

    f="${dir}/uImage"
    if [ -f "$f" ]; then
        size=$(stat -c%s "$f")
        if [ "$size" -gt "$kernel_max" ]; then
            echo "WARNING: uImage is $((size / 1024)) KiB, exceeds the 6 MiB FEL kernel budget" \
                 "(would overlap the initramfs at 0x82800000)" >&2
        fi
    fi

    f="${dir}/rootfs.cpio"
    if [ -f "$f" ]; then
        size=$(stat -c%s "$f")
        if [ "$size" -gt "$initramfs_max" ]; then
            echo "WARNING: rootfs.cpio is $((size / 1024)) KiB, exceeds the 16 MiB FEL initramfs budget" \
                 "(would overlap the DTB at 0x83A00000)" >&2
        fi
    fi
}

check_image_sizes "${OUT_DIR}"

"$BOARD_DIR"/mknandboot.sh "${OUT_DIR}/spi-nand.bin" "${OUT_DIR}"/u-boot-sunxi-with-spl.bin > /dev/null 2>&1

mkdir -p "${BUILD_DIR}"/../../../../out/"$(basename "$CONFIG_DIR")"
IMAGE_OUT=$(realpath "${BUILD_DIR}"/../../../../out/"$(basename "$CONFIG_DIR")")

mkdir -p "$IMAGE_OUT"
cp "${OUT_DIR}"/* "${IMAGE_OUT}"

echo "Images are in $IMAGE_OUT"
