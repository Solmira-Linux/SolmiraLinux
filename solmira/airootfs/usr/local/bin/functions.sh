#!/bin/bash

LOG="/tmp/solmira-install.log"

log() {
    echo "[INFO] $*" | tee -a "$LOG"
}

fail() {
    echo "[ERROR] $*" | tee -a "$LOG"
    whiptail --title "Error" --msgbox "$*" 10 60
    exit 1
}

gauge_step() {
    local percent="$1"
    local msg="$2"
    echo "$percent"
    echo "XXX"
    echo "$percent"
    echo "$msg"
    echo "XXX"
}

check_root() {
    if [[ $(id -u) -ne 0 ]]; then
        fail "Installer must be run as root."
    fi
}

welcome_screen() {
    whiptail --title "Welcome to Solmira Linux :D" \
        --msgbox "This installer will guide you through installing Solmira Linux on your computer." 10 60 \
        || exit 0
}

select_disk() {
    # Build disk menu options
    items=()
    while IFS= read -r line; do
        # Each line will be: /dev/sda "500G"
        disk=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        items+=("$disk" "$size")
    done < <(lsblk -d -o NAME,SIZE | awk 'NR>1 {print "/dev/"$1, $2}')

    # Check if any disks found
    if [ ${#items[@]} -eq 0 ]; then
        whiptail --title "Error" --msgbox "No disks detected." 8 40
        exit 1
    fi

    # Show whiptail menu
    whiptail --title "Disk Selection" \
        --menu "Select installation disk:" 20 60 10 \
        "${items[@]}" 3>&1 1>&2 2>&3
}

confirm_wipe() {
    whiptail --yesno "ALL DATA ON $1 WILL BE ERASED.\nContinue?" 10 60 \
        || fail "Installation cancelled."
}


create_partitions_fdisk() {
    DEV="$1"

    echo "Creating GPT partition table on $DEV..."
    parted -s "$DEV" mklabel gpt

    echo "Creating EFI partition (1G)..."
    parted -s "$DEV" mkpart ESP fat32 1MiB 1025MiB
    parted -s "$DEV" set 1 boot on

    echo "Creating root partition (rest of disk)..."
    parted -s "$DEV" mkpart primary ext4 1025MiB 100%

    # Refresh kernel partition table
    partprobe "$DEV"
    sleep 1

    base=$(basename "$DEV")
    if [[ "$base" =~ ^(nvme|mmcblk) ]]; then
        echo "/dev/${base}p1 /dev/${base}p2"
    else
        echo "/dev/${base}1 /dev/${base}2"
    fi
}

format_partitions() {
    EFI="$1"
    ROOT="$2"

    echo "Formatting EFI partition: $EFI"
    mkfs.fat -F32 "$EFI" || { echo "ERROR: Failed to format EFI partition"; exit 1; }

    echo "Formatting root partition: $ROOT"
    mkfs.ext4 -L "Solmira Linux Root" -F "$ROOT" || { echo "ERROR: Failed to format root partition"; exit 1; }
}

mount_partitions() {
    EFI="$1"
    ROOT="$2"

    echo "Mounting root partition: $ROOT -> /mnt"
    mount "$ROOT" /mnt || { echo "ERROR: Failed to mount root"; exit 1; }

    echo "Mounting EFI partition: $EFI -> /mnt/boot/efi"
    mkdir -p /mnt/boot/efi
    mount "$EFI" /mnt/boot/efi || { echo "ERROR: Failed to mount EFI"; exit 1; }
}

install_base() {
    pacstrap /mnt solmira-desktop || return 1
}

generate_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab || return 1
}

configure_system() {
    arch-chroot /mnt bash <<EOF || return 1
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
timedatectl set-ntp true
systemctl enable systemd-timesyncd
systemctl enable apparmor
systemctl enable NetworkManager
echo "KEYMAP=us" > /etc/vconsole.conf
EOF
}

set_hostname() {
    echo "$1" > /mnt/etc/hostname || return 1
}

create_user() {
    arch-chroot /mnt bash <<EOF || return 1
echo "root:$2" | chpasswd
useradd -m -G wheel $1
echo "$1:$2" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/00-wheel
chmod 440 /etc/sudoers.d/00-wheel
EOF
}

install_bootloader() {
    arch-chroot /mnt grub-install \
        --target=x86_64-efi \
        --efi-directory=/boot/efi \
        --bootloader-id="Solmira Linux" || return 1

    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || return 1
}

finish_screen() {
    whiptail --title "Installation Complete :D" \
        --msgbox "Solmira Linux was installed successfully.\nYou may now reboot into your new system." 10 60
}