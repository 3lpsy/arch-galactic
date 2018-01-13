#!/bin/bash


set -e

# conf.sh
source conf.sh


mkdir $MOUNT_PATH

# parition.sh
source partition.sh

# luks.sh
source luks.sh

### zfs.sh
source zfs.sh

echo "Add your hooks"
echo "Add your hooks"
echo 'HOOKS="base udev autodetect modconf block keyboard encrypt zfs usr filesystems shutdown"'
echo "run mknicpio after install arc"
echo #
# cp install.sh $MOUNT_PATH/root/install.sh
