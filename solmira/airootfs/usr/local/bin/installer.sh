#!/bin/bash
set -e

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


whiptail --title "Partitioning: 10%" --infobox "Creating partitions on $DISK..." 8 60
read EFI ROOT <<< "$(create_partitions "$DISK")" || fail "Partitioning failed."


whiptail --title "Formatting: 25%" --infobox "Formatting EFI and root partitions..." 8 60
format_partitions "$EFI" "$ROOT" || fail "Formatting failed."


whiptail --title "Mounting: 40%" --infobox "Mounting filesystem..." 8 60
mount_partitions "$EFI" "$ROOT" || fail "Mount failed."


whiptail --title "Installing Base System: 55%" --infobox "Installing Solmira Linux base system..." 8 60
install_base || fail "Base system installation failed."


whiptail --title "Generating fstab: 70%" --infobox "Generating fstab..." 8 60
generate_fstab || fail "Fstab generation failed."


whiptail --title "Configuring System: 85%" --infobox "Configuring locale, timezone, keymap, hostname, and user..." 8 60
set_locale || fail "Locale setup failed."
set_timezone || fail "Timezone setup failed."
set_keymap || fail "Keymap setup failed."
set_hostname "$HOSTNAME" || fail "Hostname setup failed."
create_user "$USERNAME" "$PASSWORD" || fail "User creation failed."


whiptail --title "Installing Bootloader: 95%" --infobox "Installing GRUB bootloader..." 8 60
install_bootloader || fail "Bootloader installation failed."


whiptail --title "Installation Complete: 100%" --msgbox \
"Solmira Linux was installed successfully!\nYou may now reboot.\nFull log: $LOG" 10 60