#!/bin/bash
# Solmira Linux Installer (Whiptail)

# Load helper functions
source "$(dirname "$0")/functions.sh"

function welcome() {
    whiptail --title "Hello! :D" --msgbox "Welcome to Solmira Linux! This setup will guide you towards installing Solmira onto your computer." 10 60
}

function select_disk() {
    local DISK
    DISK=$(lsblk -d -n -o NAME,SIZE | awk '{print $1 " " $2}' | \
        whiptail --title "Select Disk" --menu "Choose target disk:" 20 60 10 $(cat) 3>&1 1>&2 2>&3)
    echo "$DISK"
}

function confirm_disk() {
    local DISK="$1"
    whiptail --yesno "Are you sure you want to install on /dev/$DISK?" 10 60
}

# Main flow
welcome
TARGET_DISK=$(select_disk)
confirm_disk "$TARGET_DISK"
# Next: partitioning, filesystem, packages, bootloader, users
