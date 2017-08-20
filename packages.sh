#!/bin/bash

sudo pacman -Syyu xorg-server xorg-xinit xorg-xprop xorg-xrandr xf86-video-amdgpu mesa-vdpau libpau-va-gl

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

# I3 Gaps
pacaur -Syu i3-gaps
pacman -S perl-anyevent perl-json dmenu compton
pacaur -S cowsay neofetch ttf-fira-code ttf-font-awesome ttf-fira-mono
pacman -S arc-gtk-theme
sudo pacman -S feh termite firefox mpv mps-youtube youtube-dl

# cp install.sh /mnt/root/install.sh

echo "install extensions ublock-origin privacy badger httpseverywhere PASSMANAGER"
