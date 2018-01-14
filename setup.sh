#!/bin/bash

# conf
export TARGET_DISK="/dev/nvme0n1"
export TARGET_PART_BOOT="/dev/nvme0n1p1"
export TARGET_PART_ROOT="/dev/nvme0n1p2"
export ENC_NAME="enc"
export POOL_NAME='rpool'
export RPOOL_DEV="/dev/mapper/$ENC_NAME"
export MOUNT_PATH="/mnt"

if [[ ! -d $MOUNT_PATH ]]; then
    echo "Making directory: $MOUNT_PATH"
    mkdir $MOUNT_PATH
fi

# parition.sh
function run_partition() {
    echo "##### Partition $TARGET_DISK ######"
    echo "# partining disk"
    (
    echo o # Create a new empty DOS partition table
    echo Y
    echo n # Add a new partition
    echo 1 # Partition number
    echo   # First sector (Accept default: 1)
    echo +512MiB  # Last sector (Accept default: varies)
    echo ef00 # EFI SYSTEM
    echo n # Add a new partition
    echo 2 # Second Partiion
    echo # First Sector (Accept default: next available)
    echo # Last sector (Accept default: end of disk)
    echo bf00 # Solaris Root
    echo w # Write changes
    echo Y
    ) | gdisk "$TARGET_DISK"

    echo "# creating fat filesystem on $TARGET_PART_BOOT"
    mkfs.fat -F32 "$TARGET_PART_BOOT"
}


# luks.sh
function run_luks() {
    echo "##### Cryptsetup $TARGET_PART_ROOT ######"echo "yes"

    echo "# Encrypt root"
    cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 "$TARGET_PART_ROOT"
}

function run_open_luks() {
    echo "# Open partition"
    cryptsetup open --type luks "$TARGET_PART_ROOT" $ENC_NAME
}

function newpool() {
    echo "# Creating Pool: $1"
    echo "## $ zfs create -o mountpoint=none $1"
    zfs create -o mountpoint=$2 $1
}

function newcomppool() {
    echo "# Creating Legacy Pool: $1"
    echo "## $ zfs create -o -o compression=lz4 -o mountpoint=$2 $1"
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

function run_zfs() {
    echo "# Creating Root $1 "
    echo "# $ zpool create -o ashift=12 -R $MOUNT_PATH $POOL_NAME $RPOOL_DEV2"
    zpool create -o ashift=12 -R $MOUNT_PATH $POOL_NAME $RPOOL_DEV
    echo ""

    echo "Creating ROOT datasets..."
    newpool $POOL_NAME/ROOT none
    newcomppool $POOL_NAME/ROOT/default /
    echo ""

    echo "Creating DATA (sharable) datasets..."
    newpool $POOL_NAME/DATA none
    newcomppool $POOL_NAME/DATA/home /home
    echo ""

    echo "Creating SYSTEM datasets..."
    newpool $POOL_NAME/SYSTEM none
    newpool $POOL_NAME/SYSTEM/var legacy
    zfsset $POOL_NAME/SYSTEM/var xattr sa

    newpool $POOL_NAME/SYSTEM/usr legacy

    newpool $POOL_NAME/SYSTEM/tmp /tmp
    zfsset $POOL_NAME/SYSTEM/tmp sync disabledzfs
    zfsset $POOL_NAME/SYSTEM/tmp setuid off
    zfsset $POOL_NAME/SYSTEM/tmp devices off

    echo "#!!! systemctl mask tmp.mount?"
    systemctl mask tmp.mount
    zfs umount -a

    echo ""

    echo "Setting bootfs $1 for $POOL_NAME"
    zpool set bootfs=$1 $POOL_NAME
    echo ""

    zfslist
    zpoollist

    echo ""
    echo "Exporting Pool"
    zpool export $POOL_NAME

    echo "Importing Pool"
    importzpool $POOL_NAME

    echo "Unmounting tmp and home"
    zfs umount $MOUNT_PATH/tmp
    zfs umount $MOUNT_PATH/home
}

function run_mount_zfs() {
    echo "Mounting default pool on mount path"
    mount -t zfs $POOL_NAME/ROOT/default $MOUNT_PATH
    echo ""
    echo "Configuring cache"
    CACHE_FILE="/etc/zfs/zpool.cache"

    if [ -f $CACHE_FILE ]; then
        echo "Zpool cache exists"
    else
        echo "Creating zpool cache."
        zpool set cachefile=/etc/zfs/zpool.cache rpool
    fi

    echo ""

    if [ ! -d "$MOUNT_PATH/etc" ]; then
        echo "Making $MOUNT_PATH/etc"
        mkdir $MOUNT_PATH/etc
    fi
    echo ""
    if [ ! -d "$MOUNT_PATH/etc/zfs" ]; then
        echo "Making $MOUNT_PATH/etc/zfs"
        mkdir $MOUNT_PATH/etc/zfs
    fi

    echo "Copying cache"
    cp /etc/zfs/zpool.cache $MOUNT_PATH/etc/zfs/zpool.cache

    echo "Making mout directories home,boot,var,usr,tmp"
    mkdir $MOUNT_PATH/{home,boot,var,usr,tmp}

    echo "# Mouting directory boot,var,usr"
    mount $TARGET_PART_BOOT $MOUNT_PATH/boot
    mount -t zfs $POOL_NAME/SYSTEM/var $MOUNT_PATH/var
    mount -t zfs $POOL_NAME/SYSTEM/usr $MOUNT_PATH/usr

    echo "# Mouting directory home,tmp"
    zfs mount $POOL_NAME/DATA/home
    zfs mount $POOL_NAME/SYSTEM/tmp

    echo ""
    echo "Check mount..."

    zfs mount
    echo ""
}

function run_unmount_zfs() {
    echo "Unmounting tmp and home"
    zfs umount $MOUNT_PATH/tmp
    zfs umount $MOUNT_PATH/home
}

function run_close_luks() {
    cryptsetup close $RPOOL_DEV
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


function run_generatefstab() {
    addlegacytofstab $POOL_NAME/ROOT/default /
    addlegacytofstab $POOL_NAME/SYSTEM/var /var
    addlegacytofstab $POOL_NAME/SYSTEM/usr /usr
    genfstab -U -p $MOUNT_PATH >> $MOUNT_PATH/etc/fstab
}



function run_nextsteps() {
    echo "Add your hooks"
    echo "Add your hooks"
    echo 'HOOKS="base udev autodetect modconf block keyboard encrypt zfs usr filesystems shutdown"'
    echo "run mknicpio after install arc"
    echo #
    # cp install.sh $MOUNT_PATH/root/install.sh
}

function run_confirm() {
    read -p "Continue with $1 [Yes(y)/No(n)/Skip(s)]?" choice
    case "$choice" in
      y|Y ) echo 1;;
      s|S ) echo 0;;
      n|N ) exit;;
      * ) run_confirm;;
    esac
}

function print_usage() {
    cat > /dev/stdout << END
    OPTIONAL ARGS:
    --all - script to run just before actually performing test
    -p - parition disk ${TARGET_DISK}
    -l - setup luks disk on ${TARGET_DISK}
    -o - open luks parition
    -z - setup zfs on ${TARGET_DISK} and ${MOUNT_PATH}
    -m - mount zfs on ${MOUNT_PATH'}
    -g - generate fstab
    -u - unmiont zfs
    -c - close luks

END
}

function command_to_function() {
    $original="$1"
    echo -n "run_$(echo -n $original | sed 's/_/-/g')"
}

commands=("partition" "luks" "open-luks" "zfs" "mount-zfs" "generatefstab")

function run_all() {
    for command in "${commands[@]}"; do
        while true; do
            read -p "Perform: $command [Yes(y)/No(n)]?" choice
            func="$(command_to_function $command)"
            case "$choice" in
              y|Y ) $func; break;;
              n|N ) echo "Skipping $command"; break;;
              *) echo "Please answer Y/N";;
            esac
        done
    done
}

if [[ "$1" == "--all" ]]; then
    run_all;
    exit
elif [[ ${#@} -gt 0 ]]; then
    DO_RUN_PARTITION=0
    DO_RUN_LUKS=0
    DO_RUN_OPEN_LUKS=0
    DO_RUN_ZFS=0
    DO_RUN_MOUNT_ZFS=0
    DO_RUN_GENERATEFSTAB=0
    DO_RUN_UNMOUNT_ZFS=0
    DO_RUN_CLOSE_LUKS=0
    while getopts "plozmguc" opt; do
        case "${opt}" in
        p) DO_RUN_PARTIONION=1 ;;
        l) DO_RUN_LUKS=1 ;;
        o) DO_RUN_OPEN_LUKS=1 ;;
        m) DO_RUN_MOUNT_ZFS=1 ;;
        g) DO_RUN_GENERATEFSTAB=1 ;;
        u) DO_RUN_UNMOUNT_ZFS=1 ;;
        c) DO_RUN_CLOSE_LUKS=1 ;;
        esac
    done
    if [[ $DO_RUN_PARTITION -gt 0 ]]; then
        func="$(command_to_function parition)"
        echo "# Running $func"
        $func
        echo ""
    fi
    if [[ $DO_RUN_LUKS -gt 0 ]]; then
        func="$(command_to_function luks)"
        echo "# Running $func"
        $func
        echo ""
    fi
    if [[ $DO_RUN_OPEN_LUKS -gt 0 ]]; then
        func="$(command_to_function open-luks)"
        echo "# Running $func"
        $func
        echo ""
    fi
    if [[ $DO_RUN_ZFS -gt 0 ]]; then
        func="$(command_to_function zfs)"
        echo "# Running $func"
        $func
        echo ""
    fi
    if [[ $DO_RUN_MOUNT_ZFS -gt 0 ]]; then
        func="$(command_to_function mount-zfs)"
        echo "# Running $func"
        $func
        echo ""
    fi
    if [[ $DO_RUN_GENERATEFSTAB -gt 0 ]]; then
        func="$(command_to_function generatefstab)"
        echo "# Running $func"
        $func
        echo ""
    fi
    if [[ $DO_RUN_UNMOUNT_ZFS -gt 0 ]]; then
        func="$(command_to_function unmount-zfs)"
        echo "# Running $func"
        $func
        echo ""
    fi
    if [[ $DO_RUN_CLOSE_LUKS -gt 0 ]]; then
        func="$(command_to_function close-luks)"
        echo "# Running $func"
        $func
        echo ""
    fi
else
    print_usage
fi
