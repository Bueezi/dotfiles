dir=${XDG_DATA_HOME:-$HOME/.local/share}/appimages
apps=${XDG_DATA_HOME:-$HOME/.local/share}/applications
mkdir -p "$dir/.icons" "$apps"

for e in "$apps"/appimage-*.desktop; do
    [ -e "$e" ] || continue
    [ -e "$dir/$(sed -n 's/^X-AppImage-File=//p' "$e")" ] || rm -f "$e" "$dir/.icons/$(basename "$e" .desktop)".*
done

for f in "$dir"/*.AppImage "$dir"/*.appimage; do
    [ -f "$f" ] || continue
    [ "$(head -c4 "$f" | tail -c3)" = ELF ] || continue   # still downloading
    [ -x "$f" ] || chmod +x "$f"   # unconditional chmod would re-trigger the path unit forever
    name=$(basename "$f")
    id=appimage-$(printf '%s' "${name%.*}" | tr -c 'A-Za-z0-9._-' -)
    out=$apps/$id.desktop
    [ "$out" -nt "$f" ] && continue

    # The squashfs starts right after the runtime's ELF section headers
    shoff=$(od -An -tu8 -j40 -N8 "$f"); shsize=$(od -An -tu2 -j58 -N2 "$f"); shnum=$(od -An -tu2 -j60 -N2 "$f")
    tmp=$(mktemp -d)
    unsquashfs -q -n -o $((shoff + shsize * shnum)) -d "$tmp/x" "$f" '*.desktop' '*.png' '*.svg' .DirIcon >/dev/null 2>&1 || true
    entry=$(find "$tmp/x" -maxdepth 1 -name '*.desktop' 2>/dev/null | head -n1 || true)

    icon=$(readlink -f "$tmp/x/.DirIcon" 2>/dev/null || true)
    if [ ! -f "$icon" ] && [ -n "$entry" ]; then
        icon=$tmp/x/$(sed -n 's/^Icon=//p' "$entry" | head -n1 || true)
        if [ -f "$icon.png" ]; then icon=$icon.png; else icon=$icon.svg; fi
    fi
    rm -f "$dir/.icons/$id".*
    if [ -f "$icon" ]; then
        case $icon in *.svg) ext=svg ;; *) ext=png ;; esac
        cp "$icon" "$dir/.icons/$id.$ext"
        icon=$dir/.icons/$id.$ext
    else
        icon=application-x-executable
    fi

    path=$(printf '%s' "$f" | sed 's/[\\&|]/\\&/g')
    if [ -n "$entry" ]; then
        sed -e "s|^Exec=[^ ]*|Exec=\"$path\"|" -e "s|^Icon=.*|Icon=$icon|" -e '/^TryExec=/d' \
            -e "/^\[Desktop Entry\]/a X-AppImage-File=${name//\\/\\\\}" "$entry" > "$out.tmp"
    else
        printf '[Desktop Entry]\nType=Application\nName=%s\nExec="%s"\nIcon=%s\nX-AppImage-File=%s\n' "${name%.*}" "$f" "$icon" "$name" > "$out.tmp"
    fi
    mv "$out.tmp" "$out"
    rm -rf "$tmp"
done
