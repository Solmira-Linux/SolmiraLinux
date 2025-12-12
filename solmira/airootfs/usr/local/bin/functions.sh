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

# -----------------------------
# BASIC CHECKS
# -----------------------------
check_root() {
    if [ "$(id -u)" != 0 ]; then
        whiptail --title "Error" \
        --msgbox "This installer must be launched as root." 8 50
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

    CHOICE=$(whiptail --title "Select Disk" \
        --menu "Choose installation disk:" 20 60 10 \
        "${items[@]}" 3>&1 1>&2 2>&3)

    echo "$CHOICE"
}

confirm_wipe() {
    DEV="$1"
    whiptail --yesno "WARNING: This will ERASE ALL DATA on $DEV. Continue?" 10 60 || exit 1
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
set_locale() {
    LOCALE=$(whiptail --inputbox "Enter locale (default: en_US.UTF-8):" \
        10 60 "en_US.UTF-8" 3>&1 1>&2 2>&3)

    arch-chroot /mnt sed -i "s/#$LOCALE UTF-8/$LOCALE UTF-8/" /etc/locale.gen
    arch-chroot /mnt locale-gen

    echo "LANG=$LOCALE" > /mnt/etc/locale.conf
}

set_timezone() {
    TIMEZONE=$(whiptail --inputbox "Enter timezone (example: America/New_York):" \
        10 60 "America/New_York" 3>&1 1>&2 2>&3)

    arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    arch-chroot /mnt hwclock --systohc
}

set_keymap() {
    KEYMAP=$(whiptail --inputbox "Enter keyboard layout (default: us):" \
        10 60 "us" 3>&1 1>&2 2>&3)

    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
}

set_hostname() {
    HOST=$(whiptail --inputbox "Enter hostname:" \
        10 60 "solmira" 3>&1 1>&2 2>&3)

    echo "$HOST" > /mnt/etc/hostname
}

create_user() {
    USERNAME=$(whiptail --inputbox "Enter username:" \
        10 60 "user" 3>&1 1>&2 2>&3)

    PASS=$(whiptail --passwordbox "Enter password:" \
        10 60 3>&1 1>&2 2>&3)

    echo "root:$PASS" | arch-chroot /mnt chpasswd
    arch-chroot /mnt useradd -m -G wheel "$USERNAME"
    echo "$USERNAME:$PASS" | arch-chroot /mnt chpasswd

    arch-chroot /mnt bash -c 'echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/00-wheel'
    arch-chroot /mnt chmod 440 /etc/sudoers.d/00-wheel

    
}


ask_aur() {
    if whiptail --yesno "Would you like to enable the Arch User Repository (AUR) using paru?" 10 60 ; then
        echo "yes"
    else
        echo "no"
    fi
}


install_paru() {
    USERNAME="$1"

    # Install dependencies for makepkg
    arch-chroot /mnt pacman -S --noconfirm --needed base-devel git

    # Build paru in user's home directory
    arch-chroot /mnt bash -c "
        sudo -u $USERNAME bash -c '
            cd ~ &&
            git clone https://aur.archlinux.org/paru.git &&
            cd paru &&
            makepkg -si --noconfirm
        '
    "
}

# -----------------------------
# BASE SYSTEM
# -----------------------------
install_base() {
    # Base system packages
    pacstrap /mnt base linux linux-firmware networkmanager grub efibootmgr base-devel sudo nano vim

    # KDE Plasma and other applications
    pacstrap /mnt plasma-meta dolphin konsole kate partitionmanager okular libreoffice-still firefox gwenview kalk haruna elisa rustup gamemode gamescope gimp inkscape rustup &7 rustup default stable
}

generate_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
}

install_bootloader() {
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Solmira Linux"
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

finish_screen() {
    whiptail --title "Done! :D" \
    --msgbox "Solmira Linux has been successfully installed.\nYou may now reboot." 10 60
}
