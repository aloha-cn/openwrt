#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Build a bootable TWR-P1025 SD card image:
#   partition 1: FAT   - kernel uImage + device tree (loaded by the stock u-boot
#                        bootcmd via fatload from mmc 0:1)
#   partition 2: linux - squashfs rootfs, the free space behind it is used by
#                        fstools for the "rootfs_data" overlay
#
# The first 1 MiB behind the rootfs image is cleared so that no stale
# filesystem from a previous installation is detected there.

set -e -x

[ $# -eq 5 ] || {
	echo "SYNTAX: $0 <file> <bootfs image> <rootfs image> <bootfs size MiB> <rootfs size MiB>"
	exit 1
}

OUTPUT="$1"
BOOTFS="$2"
ROOTFS="$3"
BOOTFSSIZE="$4"
ROOTFSSIZE="$5"

head=4
sect=63

# 0x0e = FAT16 LBA, 0x83 = Linux
set $(ptgen -o "$OUTPUT" -h $head -s $sect -l 1024 -t e -p ${BOOTFSSIZE}M -t 83 -p ${ROOTFSSIZE}M)

BOOTOFFSET="$(($1 / 512))"
ROOTFSOFFSET="$(($3 / 512))"

dd bs=512 if="$BOOTFS" of="$OUTPUT" seek="$BOOTOFFSET" conv=notrunc
dd bs=512 if="$ROOTFS" of="$OUTPUT" seek="$ROOTFSOFFSET" conv=notrunc

ROOTFSEND="$(($ROOTFSOFFSET + ($(wc -c < "$ROOTFS") + 511) / 512))"
dd bs=512 if=/dev/zero of="$OUTPUT" seek="$ROOTFSEND" count=2048 conv=notrunc
