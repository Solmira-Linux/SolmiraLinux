#!/bin/bash
set -e

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

# -----------------------------
# BASIC CHECKS
# -----------------------------
check_root() {
    if [ "$(id -u)" != 0 ]; then
        whiptail --title "Error" --msgbox "This installer must be run as root." 8 50
        exit 1
    fi
}

welcome_screen() {
    whiptail --title "Welcome to Solmira Linux!" \
        --msgbox "This installer will guide you through installing Solmira Linux on your computer." 10 60
}

# -----------------------------
# DISK SELECTION
# -----------------------------
select_disk() {
    mapfile -t items < <(lsblk -d -o NAME,SIZE | tail -n +2 | awk '{print "/dev/"$1, $2}')
    [ "${#items[@]}" -eq 0 ] && { whiptail --msgbox "No disks detected." 8 40; exit 1; }

    whiptail --title "Select Disk" \
        --menu "Choose installation disk:" 20 60 10 \
        "${items[@]}" 3>&1 1>&2 2>&3
}

confirm_wipe() {
    whiptail --yesno "WARNING: This will ERASE ALL DATA on $1.\nContinue?" 10 60 || exit 1
}

# -----------------------------
# PARTITIONING
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
1
n
2


t
2
20
w
EOF

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
    mkfs.fat -F32 "$EFI"
    mkfs.ext4 -F "$ROOT"
}

mount_partitions() {
    EFI="$1"
    ROOT="$2"

    mount "$ROOT" /mnt
    mkdir -p /mnt/boot/efi
    mount "$EFI" /mnt/boot/efi
}

# -----------------------------
# SYSTEM CONFIGURATION
# -----------------------------
set_locale() {
    arch-chroot /mnt sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}

set_timezone() {
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
    arch-chroot /mnt hwclock --systohc
}

set_keymap() {
    echo "KEYMAP=us" > /mnt/etc/vconsole.conf
}

set_hostname() {
    HOST="$1"
    echo "$HOST" > /mnt/etc/hostname
}

create_user() {
    USERNAME="$1"
    PASS="$2"

    echo "root:$PASS" | arch-chroot /mnt chpasswd
    arch-chroot /mnt useradd -m -G wheel "$USERNAME"
    echo "$USERNAME:$PASS" | arch-chroot /mnt chpasswd

    arch-chroot /mnt bash -c 'echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/00-wheel'
    arch-chroot /mnt chmod 440 /etc/sudoers.d/00-wheel
}

# -----------------------------
# AUR HELPER
# -----------------------------
ask_aur() {
    whiptail --yesno "Enable AUR using paru?" 10 60 && echo yes || echo no
}

install_paru() {
    USER="$1"

    arch-chroot /mnt pacman -S --noconfirm --needed base-devel git

    arch-chroot /mnt sudo -u "$USER" bash -c "
        rustup default stable &&
        cd ~ &&
        git clone https://aur.archlinux.org/paru.git &&
        cd paru &&
        makepkg -si --noconfirm
    "
}

# -----------------------------
# BASE SYSTEM
# -----------------------------
install_base() {
    pacstrap /mnt solmira-desktop
}

generate_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
}

install_bootloader() {
    arch-chroot /mnt grub-install \
        --target=x86_64-efi \
        --efi-directory=/boot/efi \
        --bootloader-id="Solmira Linux"
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

finish_screen() {
    whiptail --title "Done! :D" \
        --msgbox "Solmira Linux has been successfully installed.\nYou may now reboot." 10 60
}