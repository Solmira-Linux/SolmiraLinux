#!/bin/bash
set -e

source "$(dirname "$0")/functions.sh"

LOG="/tmp/solmira-install.log"

# -----------------------------
# PRE-GAUGE INTERACTIVE PROMPTS
# -----------------------------

check_root
welcome_screen

# Disk selection
TARGET_DISK=$(select_disk)
[ -z "$TARGET_DISK" ] && exit 1
confirm_wipe "$TARGET_DISK"

# User input
HOSTNAME=$(whiptail --inputbox "Hostname:" 10 60 "solmira" 3>&1 1>&2 2>&3)
USERNAME=$(whiptail --inputbox "Username:" 10 60 "user" 3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --passwordbox "Password:" 10 60 3>&1 1>&2 2>&3)

AUR_CHOICE=$(ask_aur)

# Partition BEFORE gauge
read EFI ROOT <<< "$(create_partitions_fdisk "$TARGET_DISK")"

# -----------------------------
# GAUGE FOR LONG-RUNNING STEPS
# -----------------------------
(
    gauge_step 20 "Formatting partitions..."
    format_partitions "$EFI" "$ROOT" >>"$LOG" 2>&1

    gauge_step 30 "Mounting partitions..."
    mount_partitions "$EFI" "$ROOT" >>"$LOG" 2>&1

    gauge_step 50 "Installing base system..."
    pacstrap /mnt solmira-desktop >>"$LOG" 2>&1

    gauge_step 65 "Generating fstab..."
    generate_fstab >>"$LOG" 2>&1

    gauge_step 75 "Configuring system..."
    set_locale >>"$LOG" 2>&1
    set_timezone >>"$LOG" 2>&1
    set_keymap >>"$LOG" 2>&1
    set_hostname "$HOSTNAME" >>"$LOG" 2>&1
    create_user "$USERNAME" "$PASSWORD" >>"$LOG" 2>&1

    if [ "$AUR_CHOICE" = "yes" ]; then
        gauge_step 85 "Installing AUR helper..."
        install_paru "$USERNAME" >>"$LOG" 2>&1
    fi

    gauge_step 95 "Installing bootloader..."
    install_bootloader >>"$LOG" 2>&1

    gauge_step 100 "Finishing..."
) | whiptail --gauge "Installing Solmira Linux..." 12 60 0

finish_screen

echo "Installation complete! You can check the full log at $LOG"