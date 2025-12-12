#!/bin/bash

function partition_disk() {
    local DISK="$1"
    # Example: guided partitioning using parted
    whiptail --msgbox "Partitioning /dev/$DISK (guided example)" 10 60
    # Actual commands: parted, mkfs, etc.
}

function select_filesystem() {
    local FS=$(whiptail --title "Filesystem" --radiolist \
    "Choose a filesystem:" 15 60 4 \
    ext4 "Default, reliable" ON \
    btrfs "Supports snapshots" OFF \
    xfs "High performance" OFF \
    3>&1 1>&2 2>&3)
    echo "$FS"
}

function install_packages() {
    whiptail --msgbox "Installing base system and optional packages..." 10 60
    # Run pacstrap or equivalent commands here
}

function setup_bootloader() {
    whiptail --msgbox "Setting up bootloader..." 10 60
}
