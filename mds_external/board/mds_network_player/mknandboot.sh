#!/bin/bash
#
# Format u-boot-sunxi-with-spl.bin for the F1C100s/F1C200s SPI NAND BootROM.
#
# The eGON BootROM reads SPI NAND with only 1 KiB of useful data per 2 KiB
# physical page (second half of each page is ignored). The SPL is spread
# across consecutive pages with 1 KiB of code at the start of each page and
# 1 KiB of zero padding after. U-Boot proper is appended verbatim at 32 KiB.
#
# Output layout:
#   [page 0]   SPL[0..1KiB]   + 1 KiB zeros
#   [page 1]   SPL[1..2KiB]   + 1 KiB zeros
#   ...
#   [page 25]  SPL[25..26KiB] + 1 KiB zeros
#   [32 KiB onward]           U-Boot proper, copied verbatim
#
# Usage: mknandboot.sh <output> <u-boot-sunxi-with-spl.bin>

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <output> <u-boot-sunxi-with-spl.bin>" >&2
    exit 1
fi

OUTPUT="$1"
UBOOT="$2"

NAND_PAGE_SIZE=2048       # F1C100s SPI NAND page size in bytes
BOOTROM_READ_SIZE=1024    # BootROM reads only first 1 KiB of each page
SPL_PAGES=26              # Number of pages the SPL occupies
SPL_AREA_SIZE=$((32 * 1024))   # U-Boot proper starts here

# Start with a zero-filled SPL area (covers padding between SPL chunks).
dd if=/dev/zero of="$OUTPUT" bs=1 count=$SPL_AREA_SIZE status=none

# Spread the SPL: 1 KiB chunk at the start of each NAND page.
for i in $(seq 0 $((SPL_PAGES - 1))); do
    dd if="$UBOOT" of="$OUTPUT" \
       bs=$BOOTROM_READ_SIZE count=1 \
       iseek=$((i * BOOTROM_READ_SIZE)) oseek=$((i * NAND_PAGE_SIZE)) \
       iflag=skip_bytes oflag=seek_bytes \
       conv=notrunc status=none
done

# Append U-Boot proper (everything past the SPL area) at offset 32 KiB.
dd if="$UBOOT" of="$OUTPUT" \
   bs=$SPL_AREA_SIZE \
   iseek=1 oseek=1 \
   conv=notrunc status=none

sync
