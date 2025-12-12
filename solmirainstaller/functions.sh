#!/bin/bash

LOG="/tmp/solmira-install.log"

# -----------------------------
# GAUGE SUPPORT
# -----------------------------
gauge_step() {
    PERCENT="$1"
    MESSAGE="$2"
    echo "$PERCENT"
    echo "XXX"
    echo "$PERCENT"
    echo "$MESSAGE"
    echo "XXX"
    sleep 0.3
}

check_root() {
    if [ "$(id -u)" != 0 ]; then
        whiptail --msgbox "This installer must be launched as root." 8 50
        exit 1
    fi
}

welcome_screen() {
    whiptail --title "Hello! :D" \
    --msgbox "Welcome to Solmira Linux!\nThis installer will guide you through installing Solmira Linux on your computer." 10 60
}

# -----------------------------
# DISK SELECTION
# -----------------------------
select_disk() {
    mapfile -t items < <(lsblk -d -o NAME,SIZE | tail -n +2 | awk '{print "/dev/"$1, $2}')
    CHOICE=$(whiptail --title "Select Disk" --menu "Choose installation disk:" 20 60 10 \
        "${items[@]}" 3>&1 1>&2 2>&3)
    echo "$CHOICE"
}

confirm_wipe() {
    DEV="$1"
    whiptail --yesno "Note that this will ERASE ALL DATA on $DEV. Do you want to continue?" 10 60 || exit 1
}

# -----------------------------
# PARTITIONING (fdisk)
# -----------------------------
create_partitions_fdisk() {
    DEV="$1"

    fdisk "$DEV" <<EOF
g
n
1

+1G
t
1
n
2


t
2
23
w
EOF

    base=$(basename "$DEV")
    if [[ "$base" =~ ^(nvme|mmcblk) ]]; then
        export EFI="/dev/${base}p1"
        export ROOT="/dev/${base}p2"
    else
        export EFI="/dev/${base}1"
        export ROOT="/dev/${base}2"
    fi
}

format_partitions() {
    mkfs.fat -F32 "$EFI"
    mkfs.ext4 -F "$ROOT"
}

mount_partitions() {
    mount "$ROOT" /mnt
    mkdir -p /mnt/boot/efi
    mount "$EFI" /mnt/boot/efi
}

# -----------------------------
# SYSTEM CONFIG
# -----------------------------
set_hostname() {
    HOST=$(whiptail --inputbox "Enter hostname:" 10 60 "solmira" 3>&1 1>&2 2>&3)
    echo "$HOST" > /mnt/etc/hostname
}

create_user() {
    USERNAME=$(whiptail --inputbox "Enter username:" 10 60 "user" 3>&1 1>&2 2>&3)
    PASS=$(whiptail --passwordbox "Enter password:" 10 60 3>&1 1>&2 2>&3)

    # Set root password
    echo "root:$PASS" | arch-chroot /mnt chpasswd

    # Create user with wheel group + home directory
    arch-chroot /mnt useradd -m -G wheel "$USERNAME"

    # Set user password
    echo "$USERNAME:$PASS" | arch-chroot /mnt chpasswd

    # Enable sudo for wheel (safe because it's a controlled installer)
    arch-chroot /mnt bash -c 'echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/00-wheel'
    arch-chroot /mnt chmod 440 /etc/sudoers.d/00-wheel
}

# -----------------------------
# INSTALL BASE SYSTEM
# -----------------------------
install_base() {
    pacstrap /mnt base linux linux-firmware networkmanager grub efibootmgr base-devel ntfs-3g sudo nano vim
}

generate_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
}

install_bootloader() {
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Solmira Linux
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

finish_screen() {
    whiptail --title "Done! :D" --msgbox "Solmira Linux has been installed on your computer.\nYou can restart your system or keep using the Live Environment." 10 60
}
