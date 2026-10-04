#
# Copyright (C) 2011 OpenWrt.org
#

PART_NAME=firmware
REQUIRE_IMAGE_METADATA=1

platform_check_image() {
	return 0
}

twr_p1025_do_upgrade() {
	local tar_file="$1"
	local board_dir="$(tar tf "$tar_file" | grep -m 1 '^sysupgrade-.*/$')"
	local partdev

	board_dir="${board_dir%/}"
	[ -n "$board_dir" ] || {
		echo "Unable to find board directory in image"
		return 1
	}

	export_bootdevice && export_partdevice partdev 1 || {
		echo "Unable to find kernel partition"
		return 1
	}

	mount -t vfat -o rw,noatime "/dev/$partdev" /mnt || {
		echo "Unable to mount kernel partition"
		return 1
	}

	echo "Writing kernel..."
	tar xf "$tar_file" "${board_dir}/kernel" -O > /mnt/uimage-p1025twr.bin

	if tar tf "$tar_file" | grep -q "^${board_dir}/dtb$"; then
		echo "Writing device tree..."
		tar xf "$tar_file" "${board_dir}/dtb" -O > /mnt/uimage-p1025twr_32b.dtb
	fi

	sync
	umount /mnt

	export_partdevice partdev 2 || {
		echo "Unable to find rootfs partition"
		return 1
	}

	# The overlay (rootfs_data, created by fstools on the free space behind
	# the squashfs) is left untouched: it is reused if it still matches the
	# new rootfs and recreated otherwise.
	echo "Writing rootfs..."
	tar xf "$tar_file" "${board_dir}/root" -O | dd of="/dev/$partdev" bs=1M conv=fsync

	sync
}

twr_p1025_copy_config() {
	local partdev

	export_bootdevice && export_partdevice partdev 1 || return 1

	mount -t vfat -o rw,noatime "/dev/$partdev" /mnt || return 1
	cp -f "$UPGRADE_BACKUP" "/mnt/$BACKUP_FILE"
	sync
	umount /mnt
}

platform_copy_config() {
	case "$(board_name)" in
	fsl,TWR-P1025)
		twr_p1025_copy_config
		;;
	esac
}

platform_do_upgrade() {
	local board=$(board_name)

	case "$board" in
	fsl,TWR-P1025)
		twr_p1025_do_upgrade "$1"
		;;
	hpe,msm460|\
	ocedo,panda|\
	sophos,red-15w-rev1|\
	watchguard,firebox-t10|\
	watchguard,firebox-t15|\
	watchguard,xtm330)
		nand_do_upgrade "$1"
		;;
	*)
		default_do_upgrade "$1"
		;;
	esac
}
