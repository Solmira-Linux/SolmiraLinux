#!/bin/bash

LOG="/tmp/solmira-install.log"
exec > >(tee -a "$LOG") 2>&1

source "$(dirname "$0")/functions.sh"

check_root
welcome_screen

DISK=$(select_disk) || exit 0
confirm_wipe "$DISK"

HOSTNAME=$(whiptail --inputbox "Hostname:" 10 60 "solmira" 3>&1 1>&2 2>&3) || exit 0
USERNAME=$(whiptail --inputbox "Username:" 10 60 "user" 3>&1 1>&2 2>&3) || exit 0
PASSWORD=$(whiptail --passwordbox "Password:" 10 60 3>&1 1>&2 2>&3) || exit 0

read EFI ROOT <<< "$(create_partitions "$DISK")" || fail "Partitioning failed."

(
    gauge_step 20 "Formatting disks..."
    format_partitions "$EFI" "$ROOT" || fail "Formatting failed."

    gauge_step 30 "Mounting filesystem..."
    mount_partitions "$EFI" "$ROOT" || fail "Mount failed."

    gauge_step 50 "Installing Solmira Linux..."
    install_base || fail "pacstrap failed."

    gauge_step 65 "Generating fstab..."
    generate_fstab || fail "fstab failed."

    gauge_step 80 "Configuring system..."
    configure_system || fail "System config failed."
    set_hostname "$HOSTNAME"
    create_user "$USERNAME" "$PASSWORD"

    gauge_step 95 "Installing bootloader..."
    install_bootloader || fail "Bootloader failed."

    gauge_step 100 "Finishing..."
) | whiptail --gauge "Installing Solmira Linux..." 12 60 0

finish_screen