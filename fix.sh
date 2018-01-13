#!/bin/bash

# A Hotfix script for simply decrpyting luks and
# importing zfs pools
# Useful to pull over a local network for debug/reboot hell.
export TARGET_DISK="/dev/nvme0n1"
export TARGET_PART_BOOT="/dev/nvme0n1p1"
export TARGET_PART_ROOT="/dev/nvme0n1p2"
export ENC_NAME="enc"
export POOL_NAME='rpool'
export RPOOL_DEV="dev/mapper/$ENC_NAME"
export MOUNT_PATH="/mnt/galactic"

function getzpoolid() {
    POOLS="$(zpool import)"
    NO_SPACE="$(echo $POOLS | tr -d '\n\t\r' | sed -e 's/\s//g')"
    ID_TMP="id:"
    START="$1$ID_TMP"
    END="state:"
    PATTERN="(?<=($START)).*(?=$END)"
    ID="$(echo $NO_SPACE | grep -Po $PATTERN)"
    echo $ID
}

function importzpool() {
    POOL_ID=$(getzpoolid $1)
    echo "# zpool import $POOL_ID -R $MOUNT_PATH $POOL_NAME"
    zpool import $POOL_ID -R $MOUNT_PATH $POOL_NAME
}


echo "# Open partition"

cryptsetup open --type luks "$TARGET_PART_ROOT" $ENC_NAME

importzpool $POOL_NAME

zfs umount $MOUNT_PATH/tmp
zfs umount $MOUNT_PATH/home

mount -t zfs $POOL_NAME/ROOT/default $MOUNT_PATH

CACHE_FILE="/etc/zfs/zpool.cache"

if [ -f $CACHE_FILE ]; then
    echo "Zpool cache exists"
else
    echo "Creating zpool cache."
    zpool set cachefile=/etc/zfs/zpool.cache rpool
fi

if [ ! -d "$MOUNT_PATH/etc" ]; then
    echo "Makine $MOUNT_PATH/etc"
    mkdir $MOUNT_PATH/etc
fi
if [ ! -d "$MOUNT_PATH/etc/zfs" ]; then
    echo "Making $MOUNT_PATH/etc/zfs"
    mkdir $MOUNT_PATH/etc/zfs
fi

# cp /etc/zfs/zpool.cache $MOUNT_PATH/etc/zfs/zpool.cache

echo "Making mout directories home,boot,var,usr,tmp"
mkdir -p $MOUNT_PATH/{home,boot,var,usr,tmp}

echo "# Mouting directory boot,var,usr"
mount $TARGET_PART_BOOT $MOUNT_PATH/boot
mount -t zfs $POOL_NAME/SYSTEM/var $MOUNT_PATH/var && mount -t zfs $POOL_NAME/SYSTEM/usr $MOUNT_PATH/usr

echo "# Mouting directory home,tmp"

zfs mount $POOL_NAME/DATA/home && zfs mount $POOL_NAME/SYSTEM/tmp

echo ""
echo "Check mount..."

zfs mount
