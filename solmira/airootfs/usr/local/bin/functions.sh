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
    whiptail --title "Welcome to Solmira Linux" \
        --msgbox "This installer will guide you through installing Solmira Linux." 10 60 \
        || exit 0
}

select_disk() {
    mapfile -t items < <(lsblk -d -o NAME,SIZE | awk 'NR>1 {print "/dev/"$1, $2}')
    [[ ${#items[@]} -eq 0 ]] && fail "No disks detected."

    whiptail --title "Disk Selection" \
        --menu "Select installation disk:" 20 60 10 \
        "${items[@]}" 3>&1 1>&2 2>&3
}

confirm_wipe() {
    whiptail --yesno "ALL DATA ON $1 WILL BE ERASED.\nContinue?" 10 60 \
        || fail "Installation cancelled."
}

create_partitions() {
    local dev="$1"

    log "Partitioning $dev"

    fdisk "$dev" <<EOF || return 1
g
n
1

+1G
t
1
1
n
2


t
2
23
w
EOF

    local base
    base=$(basename "$dev")

    if [[ "$base" =~ ^(nvme|mmcblk) ]]; then
        echo "/dev/${base}p1 /dev/${base}p2"
    else
        echo "/dev/${base}1 /dev/${base}2"
    fi
}

format_partitions() {
    mkfs.fat -F32 "$1" || return 1
    mkfs.ext4 -L "Solmira Linux Root" -F "$2" || return 1
}

mount_partitions() {
    mount "$2" /mnt || return 1
    mkdir -p /mnt/boot/efi
    mount "$1" /mnt/boot/efi || return 1
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