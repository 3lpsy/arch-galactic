#!/bin/bash

source conf.sh

pacstrap -i $MOUNT_PATH base base-devel vim git xterm wget openbsd-netcat openssh dnscrypt-proxy dnsmasq dnsutils xorg-server xorg-xinit xf86-video-amdgpu  mesa-vdpau libpau-va-gl compton i3 feh termite firefox mpv mps-youtuve youtube-dl

# cp install.sh $MOUNT_PATH/root/install.sh

echo "install extensions ublock-origin privacy badger httpseverywhere PASSMANAGER"
