#!/bin/bash

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
