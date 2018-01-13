#!/bin/bash

sudo pacman -Syyu xorg-server xorg-xinit xorg-xprop xorg-xrandr xf86-video-amdgpu mesa-vdpau libpau-va-gl

# Sound
SOUNDPKGS="pulseaudio pamixer pulseaudio-alsa ponymix pavucontrol"
echo "Install sound packages $SOUNDPKGS"
sudo pacman -S $SOUNDPKGS

#Network tools
NETPKGS="dnsmasq dnscrypt-proxy"
echo "Install Network Packages $NETPKGS"
sudo pacman -S $NETPKGS
#install pacaur
mkdir ~/.aur
aurdl cower
cd cower
makpkg -si
cd ..
aurdl pacaur
cd pacaur
makepkg -si
cd ~

echo "Update pacuaur repo"
pacaur -Syu
I3PKG="i3-gaps-next-git"
echo "Install I3 $I3PKG"
pacaur -S $I3PKG
pacman -S perl-anyevent perl-json dmenu compton
I3HELPERS="feh cowsay neofetch ttf-fira-code ttf-font-awesome ttf-fira-mono"
echo "Install I3 Helpers $I3HELPERS"
pacaur -S $I3HELPERS
GTKTHEME="arc-gtk-theme"
echo "Install gtk theme $GTKTHEME"
pacman -S $GTKTHEME
MAINAPPS="feh termite firefox mpv mps-youtube youtube-dl"
echo "Install main apps $MAINAPPS"
sudo pacman -S $MAINAPPS

VMPKGS="qemu qemu-arch-extra libvirt virt-manager ovmf virt-viewer spice-gtk3 bridge-utils ebtables dnsmasq firewalld openbsd-netcat vde2"
echo "Install VM Packages $VMPKGS"
sudo pacman -S $VMPKGS

# cp install.sh $MOUNT_PATH/root/install.sh

echo "install extensions ublock-origin privacy badger httpseverywhere PASSMANAGER"
