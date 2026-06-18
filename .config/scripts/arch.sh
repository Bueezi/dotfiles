#!/bin/bash
# iwctl
#	station <device> connect "SSID"
# ping 8.8.8.8
#  gnome-themes-extratimedatectl

# gdisk, cryptsetup, mkfs

echo -n "Root Pass : " && read root_pass
echo -n "Username : " && read usr_name
echo -n "Are u using intel, amd or nvidia ? (i/a/n): " && read hardware
echo -n "Do you want linux-zen? (y/n)" && read kernel_zen
echo -n "What WM do u want gnome or sway ? (gnome/sway): " && read wm
echo -n "Are you using LUKS disk encryption (y/n): " && read encrypt

lsblk && echo -e "-------------------------------------\nDisks :" && lsblk | grep disk && echo -e "\n\n\n"

echo -n "Proceed ? (y/n) : " && read proceed

if [ "$proceed" != "y" ]; then
    echo "Aborting."
    exit 1
fi

if [ "$encrypt" == "y" ]; then
    UUID=$(cryptsetup luksUUID $(cryptsetup status cryptroot | grep 'device:' | awk '{print $2}'))
else
    UUID=$(blkid -s UUID -o value $(findmnt -n -o SOURCE /mnt))
fi

# Enable multilib in live environment & increase parallel downloads
sed -i '/#\[multilib\]/,/#Include/ s/^#//' /etc/pacman.conf
sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

if [ "$kernel_zen" == "y" ]; then
    kernel_name="linux-zen"
    kernel_pkg="$kernel_name linux-zen-headers"
else
    kernel_name="linux"
    kernel_pkg="$kernel_name"
fi

if lscpu | grep -q "GenuineIntel"; then
    ucode="intel-ucode"
else
    ucode="amd-ucode"
fi

if [ "$hardware" == "i" ]; then
    hardware="$kernel_pkg $ucode mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva libvpl vpl-gpu-rt"
elif [ "$hardware" == "a" ]; then
    hardware="$kernel_pkg $ucode mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver opencl-mesa radeontop vulkan-tools"
elif [ "$hardware" == "n" ]; then
    hardware="$kernel_pkg $ucode nvidia-open nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver"
fi



if [ "$wm" == "sway" ]; then
    wm_packages="swaybg swaylock swayidle wl-clipboard xorg-xwayland xdg-desktop-portal-wlr xdg-desktop-portal-gtk polkit polkit-gnome \
    foot fuzzel mako i3status-rust brightnessctl networkmanager-dmenu grim slurp cliphist power-profiles-daemon \
    blueman nwg-look thunar thunar-archive-plugin gnome-themes-extra eog "
    wm_packages_aur="sway-git"
elif [ "$wm" == "gnome" ]; then
    wm_packages="gdm gnome-shell gnome-control-center gnome-settings-daemon gnome-session gnome-tweaks \
    gnome-system-monitor xdg-utils xdg-desktop-portal-gnome gnome-backgrounds gnome-disk-utility \
    power-profiles-daemon nautilus gnome-calculator gnome-text-editor loupe showtime alacritty gvfs"
    wm_packages_aur="extension-manager"
fi

audio="pipewire lib32-pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack"

bash_tools="bc vim htop btop rocm-smi-lib openssh wireguard-tools curl wget bash-completion man-db \
man-pages file-roller zip unzip 7zip dosfstools less \
fastfetch cowsay cmatrix ffmpeg mpv stress gamemode lib32-gamemode fd nnn imagemagick"

fonts="noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra ttf-liberation ttf-dejavu ttf-iosevka-nerd"
apps="helix zed chromium steam discord spotify-launcher baobab libreoffice-still"
aur="librewolf-bin $wm_packages_aur"
dev="github-cli nodejs npm rust gdb python python-pip python-virtualenv podman podman-compose"
game="openrgb"
aur_slow="protonplus ani-cli"
others=""
package_list="$hardware $wm_packages $audio $bash_tools $fonts $apps $dev $game"

base="linux-firmware base base-devel git efibootmgr networkmanager sudo vi vim bluez bluez-utils ufw cryptsetup reflector qt5-wayland qt6-wayland gnome-keyring xdg-user-dirs"

pacstrap -K /mnt $base $package_list
genfstab -U /mnt >/mnt/etc/fstab
arch-chroot /mnt <<EOF

ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "arch" > /etc/hostname
echo "root:$root_pass" | chpasswd
useradd -m -G wheel "$usr_name"
echo "$usr_name:$root_pass" | chpasswd
sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

mkdir -p /home/$usr_name/{Downloads,Documents}
chown -R $usr_name:$usr_name /home/$usr_name

systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable ufw
systemctl enable power-profiles-daemon
systemctl enable fstrim.timer # SSD TRIM
ufw default deny incoming
ufw default allow outgoing
ufw enable

if [ "$wm" == "sway" ]; then
    systemctl enable polkit.service # we are using polkit instead of seatd since we need will use it with polkit-gnome for privilige evelation prompts.
    # Setup synced dotfiles.
    su - $usr_name -c "git clone --bare https://github.com/Bueezi/dotfiles.git /home/$usr_name/.dotfiles"
    su - $usr_name -c "/usr/bin/git --git-dir=/home/$usr_name/.dotfiles --work-tree=/home/$usr_name config --local status.showUntrackedFiles no"
    su - $usr_name -c "/usr/bin/git --git-dir=/home/$usr_name/.dotfiles --work-tree=/home/$usr_name checkout -f"
elif [ "$wm" == "gnome" ]; then
    systemctl enable gdm
fi

mkdir -p /boot/loader/entries
touch /boot/loader/entries/arch.conf

echo -e "default arch.conf\ntimeout 0\neditor no" > /boot/loader/loader.conf

if [ "$encrypt" == "y" ]; then
    echo -e "title   Arch Linux\nlinux   /vmlinuz-${kernel_name}\ninitrd  /${ucode}.img\ninitrd  /initramfs-${kernel_name}.img\noptions rd.luks.name=${UUID}=cryptroot root=/dev/mapper/cryptroot rw" > /boot/loader/entries/arch.conf
    sed -i -E \
        -e 's/\budev\b/systemd/g' \
        -e 's/\bkeymap\b//g' \
        -e 's/\bconsolefont\b//g' \
        -e 's/\bfilesystems\b/sd-encrypt filesystems/' \
        /etc/mkinitcpio.conf
    mkinitcpio -P
else
    echo -e "title   Arch Linux\nlinux   /vmlinuz-${kernel_name}\ninitrd  /${ucode}.img\ninitrd  /initramfs-${kernel_name}.img\noptions root=UUID=${UUID} rw" > /boot/loader/entries/arch.conf
    sed -i -E \
        -e 's/\budev\b/systemd/g' \
        -e 's/\bkeymap\b//g' \
        -e 's/\bconsolefont\b//g' \
        /etc/mkinitcpio.conf
    mkinitcpio -P
fi

# Enable multilib, parallel downloads, colors, and ILoveCandy
cp /etc/pacman.conf /etc/pacman.conf.bak
sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
sed -i '/^\[multilib\]/,/^$/ s/^#Include/Include/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/; s/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/# Misc options/a ILoveCandy' /etc/pacman.conf

sed -i 's/^#MAKEFLAGS="-j2"/MAKEFLAGS="-j'"$(nproc)"'"/g' /etc/makepkg.conf

echo "$usr_name ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers # Allow user to use sudo without password
# Yay

su - $usr_name -c "git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si --noconfirm && cd .. && rm -rf yay"

su - $usr_name -c "yay -S --noconfirm $aur $aur_slow"

sed -i "/^$usr_name ALL=(ALL) NOPASSWD: ALL$/d" /etc/sudoers # Remove NOPASSWD line

# Local Pacman mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector --country 'Belgium,France,Netherlands,Germany' --age 24 --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
# Prepend the Arch CDN at the top of the list
sed -i '1s|^|Server = https://mirror.pkgbuild.com/$repo/os/$arch\n|' /etc/pacman.d/mirrorlist

EOF
bootctl --path=/mnt/boot install

echo "Install finished !"

# things to do :
# run default.sh, disable resist fingerprinting, run dmenu_networkmanager once
