# acmanager:// links (NoHesi "Join") → Content Manager. CM open: through Proton's launcher
# service (launch option STEAM_COMPAT_LAUNCHER_SERVICE=proton), see CLAUDE.md
if ! pgrep -f 'AssettoCorsa\.exe' >/dev/null; then
    exec steam -applaunch 244210 "$1"
fi
# Steam's own copy (runs through nix-ld)
client=~/.local/share/Steam/steamrt64/pv-runtime/steam-runtime-steamrt/pressure-vessel/bin/steam-runtime-launch-client
# shellcheck disable=SC2016 # $1 expands inside the game's container
if busctl --user status com.steampowered.App244210 >/dev/null 2>&1 &&
   "$client" --inside-app=244210 \
     -c 'cd "$STEAM_COMPAT_INSTALL_PATH" && exec wine AssettoCorsa.exe "$1"' acmanager "$1"; then
    id=$(umbriel windows --json | jq -r 'map(select(
        (.app_id | test("^(steam_app_244210|assettocorsa\\.exe)$"; "i")) and ((.title // "") | test("content manager"; "i"))))
        | first | .id // empty')
    [ -z "$id" ] || umbriel msg window-focus "$id" >/dev/null
    exit 0
fi
notify-send -a acmanager -i dialog-information-symbolic "Content Manager is open" \
    "Can't pass it the link: add STEAM_COMPAT_LAUNCHER_SERVICE=proton to AC's launch options, or close CM and click again"
