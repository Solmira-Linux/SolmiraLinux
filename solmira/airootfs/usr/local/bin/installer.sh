#!/bin/bash
set -e

LOG="/tmp/solmira-install.log"
exec > >(tee -a "$LOG") 2>&1

source "$(dirname "$0")/functions.sh"


gauge_step() {
    local percent="$1"
    local msg="$2"
    whiptail --gauge "$msg" 12 60 "$percent"
    sleep 0.3
}

check_root
welcome_screen


DISK=$(select_disk) || exit 0
confirm_wipe "$DISK"

HOSTNAME=$(whiptail --inputbox "Hostname:" 10 60 "solmira" 3>&1 1>&2 2>&3) || exit 0
USERNAME=$(whiptail --inputbox "Username:" 10 60 "user" 3>&1 1>&2 2>&3) || exit 0
PASSWORD=$(whiptail --passwordbox "Password:" 10 60 3>&1 1>&2 2>&3) || exit 0

read EFI ROOT <<< "$(create_partitions "$DISK")" || fail "Partitioning failed."


gauge_step 10 "Formatting partitions..."
format_partitions "$EFI" "$ROOT" || fail "Formatting failed."

gauge_step 25 "Mounting filesystem..."
mount_partitions "$EFI" "$ROOT" || fail "Mount failed."

gauge_step 40 "Installing base system..."
install_base || fail "pacstrap failed."

gauge_step 55 "Generating fstab..."
generate_fstab || fail "fstab failed."

gauge_step 70 "Configuring system..."
set_locale || fail "Locale setup failed."
set_timezone || fail "Timezone setup failed."
set_keymap || fail "Keymap setup failed."
set_hostname "$HOSTNAME" || fail "Hostname setup failed."
create_user "$USERNAME" "$PASSWORD" || fail "User creation failed."

#AUR_CHOICE=$(ask_aur)
#if [ "$AUR_CHOICE" = "yes" ]; then
 #   gauge_step 85 "Installing AUR helper..."
  #  install_paru "$USERNAME" || fail "AUR helper installation failed."
#fi

gauge_step 95 "Installing bootloader..."
install_bootloader || fail "Bootloader installation failed."

gauge_step 100 "Finishing installation..."
finish_screen

echo "Installation has finished! You can read the full log at $LOG"