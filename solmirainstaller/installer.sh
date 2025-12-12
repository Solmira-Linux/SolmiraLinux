#!/bin/bash
set -e

source "$(dirname "$0")/functions.sh"

check_root
welcome_screen

# Start gauge
(
    gauge_step 5  "Selecting disk..."
    TARGET_DISK=$(select_disk)

    gauge_step 10 "Confirming wipe..."
    confirm_wipe "$TARGET_DISK"

    gauge_step 20 "Partitioning disk..."
    create_partitions_fdisk "$TARGET_DISK"

    gauge_step 35 "Formatting partitions..."
    format_partitions

    gauge_step 45 "Mounting partitions..."
    mount_partitions

    gauge_step 55 "Setting hostname..."
    set_hostname

    gauge_step 60 "Creating user..."
    create_user

    gauge_step 75 "Installing base system (pacstrap)..."
    install_base

    gauge_step 85 "Generating fstab..."
    generate_fstab

    gauge_step 95 "Installing bootloader..."
    install_bootloader

    gauge_step 100 "Done!"
) | whiptail --gauge "Installing Solmira Linux..." 12 60 0

finish_screen
