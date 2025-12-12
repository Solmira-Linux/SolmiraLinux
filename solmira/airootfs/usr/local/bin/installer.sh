#!/bin/bash
set -e

source "$(dirname "$0")/functions.sh"

check_root
welcome_screen

TARGET_DISK=$(select_disk)
confirm_wipe "$TARGET_DISK"


(
    gauge_step 20 "Partitioning disk..."
    create_partitions_fdisk "$TARGET_DISK"

    gauge_step 30 "Formatting partitions..."
    format_partitions

    gauge_step 40 "Mounting partitions..."
    mount_partitions

    gauge_step 55 "Installing base system..."
    install_base

    gauge_step 65 "Generating fstab..."
    generate_fstab

    gauge_step 70 "Setting hostname..."
    set_hostname

    gauge_step 75 "Configuring locale..."
    set_locale

    gauge_step 80 "Setting timezone..."
    set_timezone

    gauge_step 85 "Setting keymap..."
    set_keymap

    gauge_step 90 "Creating user..."
    create_user

    gauge_step 92 "Asking about AUR support..."
    AUR_CHOICE=$(ask_aur)

    if [ "$AUR_CHOICE" = "yes" ]; then
        gauge_step 95 "Installing AUR helper..."
        install_paru "$USERNAME"
    fi

    gauge_step 100 "Installing bootloader..."
    install_bootloader

) | whiptail --gauge "Installing Solmira Linux..." 12 60 0

finish_screen
