#!/bin/bash

source zfsfuncs.sh

RPOOL_DEV="/dev/mapper/$ENC_NAME"

function createrootpool () {
    echo "# Creating Root $1 "
    echo "# $ zpool create -o ashift=12 $1 $2"
    zpool create -o ashift=12 -R /mnt $1 $2
    echo
}

function newpool() {
    echo ""
    echo "# Creating Pool: $1"
    echo "# $ zfs create -o mountpoint=none $1"
    zfs create -o mountpoint=$2 $1
}

function newcomppool() {
    echo
    echo "# Creating Legacy Pool: $1"
    echo "# $ zfs create -o -o compression=lz4 -o mountpoint=$2 $1"
    zfs create -o compression=lz4 -o mountpoint=$2 $1
}

function zfsset() {
    echo "# Setting $2=$3 on $1"
    zfs set $2=$3 $1
}

function setmountpoint() {
    zfsset $1 mountpoint=$2
}

function setbootfs() {
    echo "# Setting bootfs $1 for $POOL_NAME"
    zpool set bootfs=$1 $POOL_NAME
}

function zfslist() {
    echo ""
    echo "---"
    zfs list
    echo "---"
    echo ""
}

function zpoollist() {
    echo ""
    echo "---"
    zpool list
    echo "---"
    echo ""
}


function addtostab() {
    echo "$1    $2  $3  $4  $5  $6" >> /etc/fstab
}

function addlegacytofstab() {
    TARG="$1"
    MON="$2"
    TYP="zfs"
    OPTIONS="rw,relatime,xattr,noacl"
    AT="0"
    RELA="0"
    addtostab $TARG $MON $TYPE $OPTIONS $AT $RELA
}

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

function getbootuuid() {
    echo "getbootuuid"
}

function getbootstabentry() {
    TARG="UUID=$(getbootuuid)"
    MON="rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro"
    TYP="vfat"
    OPTIONS="rw,relatime,xattr,noacl"
    AT="0"
    RELA="0"
    echo "TARG MON TYPE OPTIONS AT RELA"
}

createrootpool $POOL_NAME $RPOOL_DEV
echo "Creating ROOT datasets..."
newpool $POOL_NAME/ROOT none
newcomppool $POOL_NAME/ROOT/default /
addlegacytofstab $POOL_NAME/ROOT/default /
echo "Creating DATA (sharable) datasets..."

newpool $POOL_NAME/DATA none
newcomppool $POOL_NAME/DATA/home /home

echo "Creating SYSTEM datasets..."
newpool $POOL_NAME/SYSTEM none

newpool $POOL_NAME/SYSTEM/var legacy
zfsset $POOL_NAME/SYSTEM/var xattr sa
addlegacytofstab $POOL_NAME/SYSTEM/var /var

newpool $POOL_NAME/SYSTEM/usr legacy
addlegacytofstab $POOL_NAME/SYSTEM/usr /usr

newpool $POOL_NAME/SYSTEM/tmp /tmp
zfsset $POOL_NAME/SYSTEM/tmp sync disabled
zfsset $POOL_NAME/SYSTEM/tmp setuid off
zfsset $POOL_NAME/SYSTEM/tmp devices off

echo "#!!! systemctl mask tmp.mount?"
systemctl mask tmp.mount
zfs umount -a

setbootfs $POOL_NAME/ROOT

zfslist
zpoollist

zpool export $POOL_NAME

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

cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache

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

#BOOT_FSTAB_ENTRY="$(getbootstabentry)"
#echo "# $BOOT_FSTAB_ENTRY"

genfstab -U -p /mnt >> /mnt/etc/fstab
