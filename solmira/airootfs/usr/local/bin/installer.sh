#!/bin/bash
set -e

source "$(dirname "$0")/functions.sh"

# -----------------------------
# PRE-GAUGE INTERACTIVE PROMPTS
# -----------------------------

check_root
welcome_screen

# Disk selection and wipe confirmation
TARGET_DISK=$(select_disk)
confirm_wipe "$TARGET_DISK"

# System configuration prompts
set_hostname
set_locale
set_timezone
set_keymap

# User creation
create_user
export USERNAME  # make available for AUR installation

# Ask about AUR
AUR_CHOICE=$(ask_aur)

# -----------------------------
# GAUGE FOR LONG-RUNNING STEPS
# -----------------------------
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

    if [ "$AUR_CHOICE" = "yes" ]; then
        gauge_step 75 "Installing AUR helper..."
        install_paru "$USERNAME"
    fi

    gauge_step 90 "Installing bootloader..."
    install_bootloader

    gauge_step 100 "Done!"
) | whiptail --gauge "Installing Solmira Linux..." 12 60 0

# -----------------------------
# FINISH
# -----------------------------
finish_screen
