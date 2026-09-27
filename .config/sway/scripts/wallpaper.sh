#!/usr/bin/env bash
# Pick a wallpaper from ~/Documents/wp with fuzzel and apply it to all outputs with an awww
# transition. The choice is kept as a symlink so it survives reloads/reboots.

dir="$HOME/Documents/wp"
state="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"

[ -d "$dir" ] || { notify-send "Wallpaper" "$dir not found"; exit 1; }

mapfile -t walls < <(
    find "$dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
        -printf '%f\n' | sort
)
[ ${#walls[@]} -gt 0 ] || { notify-send "Wallpaper" "No images in $dir"; exit 1; }

current=$(basename "$(readlink -f "$state" 2>/dev/null)")

choice=$(
    { echo "Random"; printf '%s\n' "${walls[@]}"; } |
    fuzzel --dmenu --prompt "wallpaper › " --select "$current"
) || exit 0

if [ "$choice" = "Random" ]; then
    choice=$(printf '%s\n' "${walls[@]}" | grep -vxF -- "$current" | shuf -n1)
    [ -n "$choice" ] || choice="$current"
fi

path="$dir/$choice"
[ -f "$path" ] || exit 1

mkdir -p "$(dirname "$state")"
ln -sfn "$path" "$state"
# Start the daemon if it isn't running (it's normally started at login)
awww query >/dev/null 2>&1 || { awww-daemon & until awww query >/dev/null 2>&1; do sleep 0.1; done; }
# "any": the circle grows from a random point on the screen
awww img "$path" --transition-type any --transition-duration 1.2 --transition-fps 144
