#!/bin/bash
ROOTFS_PATH=$(find . -maxdepth 1 -mindepth 1 -type d -name .debos-*)/root
ROOTFS_SIZE=$(du -sm $ROOTFS_PATH | awk '{ print $1 }')

ZIP_NAME=${1}
WORK_DIR="android-recovery-flashing-template"
IMG_SIZE=$(( ${ROOTFS_SIZE} + 250 )) # FIXME 250MB contingency
IMG_MOUNTPOINT=".image"

# create root img
echo "Creating an empty root image"
dd if=/dev/zero of="${WORK_DIR}/data/rootfs.img" bs=1M count=${IMG_SIZE}
mkfs.ext4 -O ^metadata_csum -O ^64bit -F "${WORK_DIR}/data/rootfs.img"

# mount the image
echo "Mounting root image"
mkdir -p $IMG_MOUNTPOINT
mount -o loop "${WORK_DIR}/data/rootfs.img" ${IMG_MOUNTPOINT}

# copy rootfs content
echo "Syncing rootfs content"
rsync --archive -H -A -X $ROOTFS_PATH/* ${IMG_MOUNTPOINT}
rsync --archive -H -A -X $ROOTFS_PATH/.[^.]* ${IMG_MOUNTPOINT}
sync

# umount the image
echo "umount root image"
umount $IMG_MOUNTPOINT

# Copy kernel and stuff
bootimage=$(find "${ROOTFS_PATH}/boot" -iname boot.img* -type f | head -n 1)
recovery=$(find "${ROOTFS_PATH}/boot" -iname recovery.img* -type f | head -n 1)
dtbo=$(find "${ROOTFS_PATH}/boot" -iname dtbo.img* -type f | head -n 1)
vbmeta=$(find "${ROOTFS_PATH}/boot" -iname vbmeta.img* -type f | head -n 1)

[ -e "${bootimage}" ] && cp "${bootimage}" ${WORK_DIR}/data/boot.img
[ -e "${recovery}" ] && cp "${recovery}" ${WORK_DIR}/data/recovery.img
[ -e "${dtbo}" ] && cp "${dtbo}" ${WORK_DIR}/data/dtbo.img
[ -e "${vbmeta}" ] && cp "${vbmeta}" ${WORK_DIR}/data/vbmeta.img

# generate flashable zip
echo "Generating recovery flashable zip"
(cd ${WORK_DIR}; zip -r9 ../out/$ZIP_NAME * -x .git README.md *placeholder)

echo "done."
