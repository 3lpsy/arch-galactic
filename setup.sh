#!/bin/bash

# conf.sh
source conf.sh

# parition.sh
source partition.sh

# luks.sh
source luks.sh

### zfs.sh
source zfs.sh

### zfs.sh
source pacstrap.sh

echo "Add your hooks"
echo "Add your hooks"
echo 'HOOKS="base udev autodetect modconf block keyboard encrypt zfs usr filesystems shutdown"'
echo "run mknicpio after install arc"
echo #
# cp install.sh /mnt/root/install.sh
