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
    echo "# zpool import $POOL_ID -R /mnt $POOL_NAME"
    zpool import $POOL_ID -R /mnt $POOL_NAME
}


echo "# Open partition"

cryptsetup open --type luks "$TARGET_PART_ROOT" $ENC_NAME

importzpool $POOL_NAME

zfs umount /mnt/tmp
zfs umount /mnt/home

mount -t zfs $POOL_NAME/ROOT/default /mnt

CACHE_FILE="/etc/zfs/zpool.cache"

if [ -f $CACHE_FILE ]; then
    echo "Zpool cache exists"
else
    echo "Creating zpool cache."
    zpool set cachefile=/etc/zfs/zpool.cache rpool
fi

if [ ! -d "/mnt/etc" ]; then
    echo "Makine /mnt/etc"
    mkdir /mnt/etc
fi
if [ ! -d "/mnt/etc/zfs" ]; then
    echo "Making /mnt/etc/zfs"
    mkdir /mnt/etc/zfs
fi

# cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache

echo "Making mout directories home,boot,var,usr,tmp"
mkdir /mnt/{home,boot,var,usr,tmp}

echo "# Mouting directory boot,var,usr"
mount $TARGET_PART_BOOT /mnt/boot
mount -t zfs $POOL_NAME/SYSTEM/var /mnt/var && mount -t zfs $POOL_NAME/SYSTEM/usr /mnt/usr

echo "# Mouting directory home,tmp"

zfs mount $POOL_NAME/DATA/home && zfs mount $POOL_NAME/SYSTEM/tmp

echo ""
echo "Check mount..."

zfs mount
