#!/bin/bash

function install_video() {
    pacman -Syyu xorg-server xorg-xinit xorg-xprop xorg-xrandr xf86-video-amdgpu mesa-vdpau libpau-va-gl
}

function install_desktop() {
    pacman -S sway
}

function install_remote() {
    pacman -S openssh
}

function install_browser() {
    MAINAPPS="feh termite firefox mpv mps-youtube youtube-dl"
    echo "Install main apps $MAINAPPS"
    sudo pacman -S $MAINAPPS
}

function install_arc_theme() {
    GTKTHEME="arc-gtk-theme"
    echo "Install gtk theme $GTKTHEME"
    pacman -S $GTKTHEME
}

function install_sound() {
    # Sound
    SOUNDPKGS="pulseaudio pamixer pulseaudio-alsa ponymix pavucontrol"
    echo "Install sound packages $SOUNDPKGS"
    pacman -S $SOUNDPKGS
}

function install_net() {
    #Network tools
    NETPKGS="dnsmasq"
    echo "Install Network Packages $NETPKGS"
    pacman -S $NETPKGS
}

function install_pacaur() {
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
}

function install_vm_host() {
    VMPKGS="qemu qemu-arch-extra libvirt virt-manager ovmf virt-viewer spice-gtk3 bridge-utils ebtables dnsmasq firewalld openbsd-netcat vde2"
    echo "Install VM Packages $VMPKGS"
    sudo pacman -S $VMPKGS
}

function usage() {
    echo "install_video"
    echo "install_desktop"
    echo "install_remote"
    echo "install_browser"
    echo "install_arc_theme"
    echo "install_sound"
    echo "install_pacaur"
    echo "install_vm_host"
}
