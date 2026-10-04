# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

DEVICE_VARS += DTB_SIZE

define Build/pad-dtb
	$(call Image/BuildDTB,$(DTS_DIR)/$(DEVICE_DTS).dts,$(dir $@)/image-$(DEVICE_DTS).dtb,,--space $(DTB_SIZE))
endef

# Bootable SD card image: MBR with a FAT "boot" partition holding the kernel
# uImage and the device tree, plus a squashfs rootfs partition. The stock
# TWR-P1025 bootcmd loads both files with "fatload mmc 0:1" and the unused
# space behind the rootfs is used by fstools for the "rootfs_data" overlay.
# $(1): name of the kernel image on the boot partition
# $(2): name of the device tree on the boot partition
define Build/sdcard-img
	rm -rf $@.boot $@.boot.fat
	mkdir -p $@.boot

	$(CP) $(IMAGE_KERNEL) $@.boot/$(word 1,$(1))
	$(CP) $(KDIR)/image-$(notdir $(DEVICE_DTS)).dtb $@.boot/$(word 2,$(1))

	mkfs.fat -n boot -C $@.boot.fat $$(($(CONFIG_TARGET_KERNEL_PARTSIZE) * 1024))
	mcopy -i $@.boot.fat $@.boot/$(word 1,$(1)) $@.boot/$(word 2,$(1)) ::/

	./gen_sdcard_img.sh \
		$@ $@.boot.fat $(IMAGE_ROOTFS) \
		$(CONFIG_TARGET_KERNEL_PARTSIZE) $(CONFIG_TARGET_ROOTFS_PARTSIZE)

	rm -rf $@.boot $@.boot.fat
endef

define Device/Default
  PROFILES := Default
  DEVICE_DTS := $(lastword $(subst _, ,$(1)))
  KERNEL_DEPENDS = $$(wildcard $(DTS_DIR)/$$(DEVICE_DTS).dts)
  KERNEL_ENTRY := 0x00000000
  KERNEL_LOADADDR := 0x00000000
  KERNEL := kernel-bin
endef

include $(SUBTARGET).mk

$(eval $(call BuildImage))
