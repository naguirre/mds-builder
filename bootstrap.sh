#!/bin/bash
#
# MDS Network Player bootstrap + NAND provisioning (host side).
#
# Pushes the RAM-only bootstrap image over USB FEL, lets U-Boot autoboot it,
# waits for SSH on the USB-Ethernet gadget, then writes the bootloader
# and rootfs onto the SPI NAND.
#
# Usage:  ./bootstrap.sh [/dev/ttyUSB0]
#
#   The serial device is OPTIONAL and used for read-only monitoring of the
#   boot. Nothing is ever written to it, but it can be useful for debugging 
#   if the board doesn't boot properly.
#
set -euo pipefail

EX_MISSING=3
EX_FEL=4
EX_SSH_TIMEOUT=5
EX_FLASH=6

BOARD_IP="192.168.2.2"
SSH_USER="root"
SSH_PASS="${SSH_PASS:-root}"  # board uses Dropbear password auth (root/root)
SSH_WAIT_TIMEOUT=120          # seconds to wait for SSH after FEL push
SUNXI_FEL="${SUNXI_FEL:-$HOME/Dev/sunxi-tools/sunxi-fel}"

# RAM layout — must match uboot.bootstrap.env
ADDR_KERNEL=0x80000000
ADDR_RAMDISK=0x82800000
ADDR_FDT=0x83A00000

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
          -o ConnectTimeout=30 -o LogLevel=ERROR
          -o PreferredAuthentications=password -o PubkeyAuthentication=no)
SCP_OPTS=(-O "${SSH_OPTS[@]}")

# The board only accepts password auth, so every non-interactive ssh/scp goes
# through sshpass. SSHPASS is read from the environment by `sshpass -e`.
export SSHPASS="$SSH_PASS"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERIAL_DEV="${1:-}"
SERIAL_PID=""

log()  { printf '\033[1;34m>>> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit "${2:-1}"; }

# Echo the exact command (one shell-quoted line), then run it.
run() {
    printf '\033[0;36m$ %s\033[0m\n' "$(printf '%q ' "$@")" >&2
    "$@"
}

# Echo a remote command line, then run it on the board over SSH.
run_remote() {
    printf '\033[0;36m[%s] $ %s\033[0m\n' "$BOARD_IP" "$*" >&2
    sshpass -e ssh "${SSH_OPTS[@]}" "${SSH_USER}@${BOARD_IP}" "$@"
}

# Locate an artifact: next to the script, else in out/<machine>/.
find_artifact() {
    local name="$1" machine="$2" p
    for p in "${SCRIPT_DIR}/${name}" \
             "${SCRIPT_DIR}/out/${machine}/${name}" \
             "${SCRIPT_DIR}/${machine}/${name}"; do
        if [ -f "$p" ]; then printf '%s\n' "$p"; return 0; fi
    done
    return 1
}

cleanup() {
    if [ -n "$SERIAL_PID" ] && kill -0 "$SERIAL_PID" 2>/dev/null; then
        kill "$SERIAL_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# --- resolve artifacts ------------------------------------------------------
UBOOT=$(find_artifact u-boot-sunxi-with-spl.bin network_player_bootstrap) \
    || die "u-boot-sunxi-with-spl.bin not found (build network_player_bootstrap first)" $EX_MISSING
UIMAGE=$(find_artifact uImage network_player_bootstrap) \
    || die "uImage not found (build network_player_bootstrap first)" $EX_MISSING
RAMDISK=$(find_artifact rootfs.cpio.uboot network_player_bootstrap) \
    || die "rootfs.cpio.uboot not found (build network_player_bootstrap first)" $EX_MISSING
DTB=$(find_artifact suniv-f1c200s-mds-network-streamer-v1.0.dtb network_player_bootstrap) \
    || die "DTB not found (build network_player_bootstrap first)" $EX_MISSING

# Production artifacts to flash onto NAND.
SPI_NAND=$(find_artifact spi-nand.bin network_player) \
    || die "spi-nand.bin not found (build network_player first)" $EX_MISSING
ROOTFS_UBIFS=$(find_artifact rootfs.ubifs network_player) \
    || die "rootfs.ubifs not found (build network_player first)" $EX_MISSING

[ -x "$SUNXI_FEL" ] || die "sunxi-fel not found/executable at $SUNXI_FEL (set SUNXI_FEL=...)" $EX_MISSING
command -v sshpass >/dev/null 2>&1 || die "sshpass not found (the board uses password auth; install sshpass)" $EX_MISSING

# --- start serial monitor (read-only, optional) -----------------------------
if [ -n "$SERIAL_DEV" ]; then
    if [ -c "$SERIAL_DEV" ]; then
        log "Monitoring serial $SERIAL_DEV (read-only)"
        stty -F "$SERIAL_DEV" 115200 raw -echo 2>/dev/null || true
        ( sed -u 's/^/[serial] /' < "$SERIAL_DEV" ) &
        SERIAL_PID=$!
    else
        warn "Serial device $SERIAL_DEV not found — continuing without monitoring"
    fi
else
    log "No serial device given — continuing without monitoring"
fi

# --- drop stale host key ----------------------------------------------------
ssh-keygen -R "$BOARD_IP" >/dev/null 2>&1 || true

# --- push the bootstrap image over FEL --------------------------------------
log "Pushing bootstrap image over USB FEL"
if ! run "$SUNXI_FEL" -v uboot "$UBOOT" \
        write-with-progress "$ADDR_KERNEL"  "$UIMAGE" \
        write-with-progress "$ADDR_RAMDISK" "$RAMDISK" \
        write-with-progress "$ADDR_FDT"     "$DTB"; then
    die "sunxi-fel push failed — is the board in FEL mode?" $EX_FEL
fi
log "FEL push done; U-Boot will autoboot into RAM"

# --- wait for SSH -----------------------------------------------------------
log "Waiting for SSH on ${SSH_USER}@${BOARD_IP} (up to ${SSH_WAIT_TIMEOUT}s)"
deadline=$((SECONDS + SSH_WAIT_TIMEOUT))
until sshpass -e ssh "${SSH_OPTS[@]}" "${SSH_USER}@${BOARD_IP}" true 2>/dev/null; do
    if [ "$SECONDS" -ge "$deadline" ]; then
        die "timed out waiting for SSH (check the USB-Ethernet host iface is 192.168.2.1/24)" $EX_SSH_TIMEOUT
    fi
    sleep 2
done
log "SSH is up"

# --- provision the NAND -----------------------------------------------------
log "Copying production artifacts to the board"
SCRATCH=/tmp
run sshpass -e scp "${SCP_OPTS[@]}" "$SPI_NAND"     "${SSH_USER}@${BOARD_IP}:${SCRATCH}/spi-nand.bin"   || die "scp spi-nand.bin failed" $EX_FLASH
run sshpass -e scp "${SCP_OPTS[@]}" "$ROOTFS_UBIFS" "${SSH_USER}@${BOARD_IP}:${SCRATCH}/rootfs.ubifs"   || die "scp rootfs.ubifs failed" $EX_FLASH

log "Erasing MTD partitions"
run_remote 'for m in 0 1 2 3; do flash_erase /dev/mtd$m 0 0; done' || die "flash_erase failed" $EX_FLASH

log "Formatting and creating UBI volumes (fota/rootfs/data)"
run_remote 'ubiformat /dev/mtd1 -y; ubiformat /dev/mtd2 -y; ubiformat /dev/mtd3 -y' || die "ubiformat failed" $EX_FLASH
run_remote 'ubiattach -p /dev/mtd1; ubiattach -p /dev/mtd2; ubiattach -p /dev/mtd3' || die "ubiattach failed" $EX_FLASH
run_remote 'ubimkvol /dev/ubi0 -N fota -m; ubimkvol /dev/ubi1 -N rootfs -m; ubimkvol /dev/ubi2 -N data -m' || die "ubimkvol failed" $EX_FLASH

log "Writing bootloader to mtd0 and rootfs to ubi1_0"
run_remote "flashcp ${SCRATCH}/spi-nand.bin /dev/mtd0" || die "flashcp failed" $EX_FLASH
run_remote "ubiupdatevol /dev/ubi1_0 ${SCRATCH}/rootfs.ubifs" || die "ubiupdatevol failed" $EX_FLASH

log "Provisioning complete — rebooting the board"
run_remote 'reboot' 2>/dev/null || warn "reboot did not return cleanly; power-cycle if the board does not reset (watchdog reset may be missing)"

log "Done. The board should now boot from NAND."
