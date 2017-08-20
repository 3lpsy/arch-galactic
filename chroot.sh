# conf.sh
source conf.sh

echo "Adding. archzfs repo to pacman.conf"

AFS_SERV="[archzfs]\nServer = http://archzfs.com/\$repo/x86_64"

echo $AFS_SERV >> /etc/pacman.conf

echo "Enter Archsfs key: https://wiki.archlinux.org/index.php/Unofficial_user_repositories#archzfs"

read AFS_KEY
echo $AFS_KEY
pacman-key -r $AFS_KEY
pacman-key --lsign-key $AFS_KEY
pacman -Syyu
pacman -S  zfs-linux

echo "Set Root Password"
passwd root
echo "Create sudo group"
groupadd sudo
echo "Create new user"
read USERNAME
useradd -m sudo -s /bin/bash $USERNAME
passwd $USERNAME

echo "I hope you added hooks"
mkinitcpio -o linux

echo "Edit /boot/loaders/loader.conf"
echo "Edit /boot/loaders/entries/arch.conf"
echo "bootctrl install --path=/boot"
echo "Edit fstab, remove non-legacy except root and correct /boot UUID"
echo "Go for it"
