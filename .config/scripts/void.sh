# load installer to ram
# root:voidlinux
# bash
# setfont -d
# fdisk partitions: 1gb vfat at /boot, swap(1.5* ram if wanna hibernate), ext4
# mkfs
# mount /mnt and /mnt/boot
# mkdir -p /mnt/var/db/xbps/keys
# cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys
# REPO=https://repo-default.voidlinux.org/current/musl
# XBPS_ARCH=x86_64-musl xbps-install -S -r /mnt base-container linux linux-firmware bash vim cpio kpartx kmod eudev ncurses kbd dhcpcd booster
# xgenfstab -U /mnt >> /mnt/etc/fstab
# xchroot /mnt /bin/bash
# ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
# echo "void" > /etc/hostname
# if glibc set locale
# useradd -mG wheel,audio,video,storage,optical,plugdev ben
# passwd
# install opendoas
# echo "permit ben as root" > /etc/doas.conf
# install gummiboot
# bootctl install --path=/boot
# remove dracut
# xbps-reconfigure -fa
# exit
# umount -R /mnt
#
# void-installer
#


echo -n "What WM do u want gnome or sway ? (gnome/sway): " && read wm
echo -n "Are u using intel, amd ? (i/a): " && read hardware

echo "max-transactions=10" > /etc/xbps.d/xbps.conf
xbps-install -Su void-repo-nonfree #void-repo-multilib void-repo-multilib-nonfree
echo "repository=https://github.com/index-0/librewolf-void/releases/latest/download/" > /etc/xbps.d/20-librewolf.conf

if lscpu | grep -q "GenuineIntel"; then
    ucode="intel-ucode" # intel-ucode needs initramfs regeneration!!!
else
    ucode="linux-firmware-amd" # both cpu & gpu
fi

if [ "$hardware" == "i" ]; then
    hardware="$ucode mesa-dri vulkan-loader mesa-vulkan-intel mesa-vaapi libvdpau-va-gl"
elif [ "$hardware" == "a" ]; then
    hardware="$ucode mesa-dri vulkan-loader mesa-vulkan-radeon mesa-vaapi libvdpau-va-gl"
fi

# need to set LIBVA_DRIVER_NAME to radeonsi and VDPAU_DRIVER to va_gl
wifi="iwd"

if [ "$wm" == "sway" ]; then
  wm_packages="sway swaybg foot fuzzel mako polkit-gnome brightnessctl power-profiles-daemon \
   blueman wl-clipboard cliphist swaylock swayidle seatd polkit nwg-look \
   i3status-rust grim slurp"
elif [ "$wm" == "gnome" ]; then
  wm_packages="elogind gnome-core alacritty gnome-calculator gnome-tweaks loupe showtime papers \
  power-profiles-daemon extension-manager gnome-system-monitor gnome-backgrounds gsound"
fi

audio="pipewire wireplumber alsa-pipewire libjack-pipewire bluez libspa-bluetooth rtkit"
apps="helix librewolf chromium baobab libreoffice"
fonts="font-iosevka noto-fonts-ttf font-awesome"
bash_tools="git bc vim htop btop openssh wireguard-tools curl wget bash-completion man-db \
man-pages zip unzip 7zip ntfs-3g dosfstools less \
fastfetch cowsay cmatrix ffmpeg mpv stress gamemode fd nnn"
dev="github-cli nodejs rust cargo gdb python3 python3-pip python3-virtualenv podman podman-compose"
base="nftables dbus xorg-server-xwayland xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-user-dirs qt5-wayland qt6-wayland gnome-keyring libva-utils"

packages="$hardware $wm_packages $wifi $apps $fonts $bash_tools $audio $dev $base"

# install
xbps-install -Su $packages

if echo "$packages" | grep -q intel-ucode; then
    xbps-reconfigure -f linux
fi

# Services to enable (run these after reboot into the base system)
ln -s /etc/sv/dbus /var/service/
ln -s /etc/sv/seatd /var/service/
ln -s /etc/sv/power-profiles-daemon /var/service/
ln -s /etc/sv/bluetoothd /var/service/
ln -s /etc/sv/nftables /var/service/ # firewall
ln -s /etc/sv/iwd /var/service/
ln -s /etc/sv/rtkit /var/service/ # Needed for Pipewire priority

ln -s /etc/sv/polkitd /var/service/

# Add your user to required groups
usermod -aG _seatd,audio,video,input,bluetooth "$USER"

# add dotfiles and dotfiles git syncing command
# git clone --bare https://github.com/Bueezi/dotfiles.git $HOME/.dotfiles
# cfg() { /usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
# cfg config --local status.showUntrackedFiles no
# cfg checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | xargs -I{} rm -f -- "$HOME/{}"
# cfg checkout

# things to do after install :
# exec pipewire manually in sway : exec pipewire & exec wireplumber & exec pipewire-pulse
# exec polkit gnome in sway : exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
# set XDG_RUNTIME_DIR in bash_profile : export XDG_RUNTIME_DIR=/run/user/$(id -u)
# running sway : dbus-run-session sway
