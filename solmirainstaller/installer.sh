#!/bin/bash
set -e

# Load functions
source "$(dirname "$0")/functions.sh"

# ---------- START ----------
check_root
welcome_screen

TARGET_DISK=$(select_disk)
confirm_wipe "$TARGET_DISK"

create_partitions_fdisk "$TARGET_DISK"
format_partitions
mount_partitions

set_hostname
create_user
install_base
generate_fstab
install_bootloader

finish_screen
