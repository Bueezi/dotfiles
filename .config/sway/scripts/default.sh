#!/usr/bin/env bash

echo "Setting default applications..."

# File manager
xdg-mime default thunar.desktop inode/directory

# Browser - LibreWolf
xdg-mime default librewolf.desktop x-scheme-handler/http
xdg-mime default librewolf.desktop x-scheme-handler/https
xdg-mime default librewolf.desktop text/html
xdg-mime default librewolf.desktop application/xhtml+xml
xdg-settings set default-web-browser librewolf.desktop

# Image viewer
xdg-mime default org.gnome.eog.desktop image/jpeg
xdg-mime default org.gnome.eog.desktop image/jpg
xdg-mime default org.gnome.eog.desktop image/png
xdg-mime default org.gnome.eog.desktop image/gif
xdg-mime default org.gnome.eog.desktop image/bmp
xdg-mime default org.gnome.eog.desktop image/webp
xdg-mime default org.gnome.eog.desktop image/tiff

# Video/Audio player (MPV)
# You must list explicit formats rather than using wildcards
xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo
xdg-mime default mpv.desktop audio/mpeg audio/x-wav audio/flac audio/ogg

# PDF viewer -> LibreWolf
xdg-mime default librewolf.desktop application/pdf

# Text editor (Helix via Foot)
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/helix.desktop << 'EOF'
[Desktop Entry]
Name=Helix
Exec=foot helix %F
Terminal=false
Type=Application
MimeType=text/plain;
Categories=Development;TextEditor;
EOF

# Update desktop database so the system sees the new helix.desktop file immediately
update-desktop-database ~/.local/share/applications

xdg-mime default helix.desktop text/plain
xdg-mime default helix.desktop text/x-c
xdg-mime default helix.desktop text/x-c++
xdg-mime default helix.desktop text/x-java
xdg-mime default helix.desktop text/x-python
xdg-mime default helix.desktop application/x-shellscript

# config git
git config --global user.email "mail@b3n.me"
git config --global user.name "Bueezi"
git config --global core.editor "hx"

# enable audio
# systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "Done!"
