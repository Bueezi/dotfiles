# What the desktop (Umbriel + Noctalia, noctalia.nix) runs on: login keyring, portals, themes,
# default apps, fonts, the file manager, and the tools ~/.config/wm/scripts call
{ config, lib, pkgs, ... }:

let
  # Cursor and icon themes for XCURSOR_*, GTK and dconf below; Umbriel's [input.cursor] (written
  # below) and the greeter (noctalia.nix) use the same. To revert: "Adwaita" for both
  cursorTheme = "Bibata-Modern-Classic";
  cursorSize = 20;   # also in ~/.config/gtk-3.0/settings.ini (X11 apps' fallback)
  # Dark is the default
  iconTheme = "Papirus-Dark";   # grey folders instead of blue (papirusGrey below)
  gtkTheme = "Mono-dark";   # adw-gtk3-dark in black: ~/.local/share/themes/Mono-dark (a real file)

  # Papirus with grey folders, like papirus-folders (papirus-icon-theme.override { color = "grey"; })
  # but in seconds: that rebuilt the whole theme (~80k icons) on every machine at every nixpkgs
  # update, 10+ minutes. Here: links to the cached theme, each folder icon pointed at its grey one
  # (all but 16x16, which papirus-folders leaves alone)
  papirusGrey = pkgs.runCommand "papirus-icon-theme-grey" { nativeBuildInputs = [ pkgs.gtk3 pkgs.lndir ]; } ''
    mkdir -p $out/share/icons
    for t in ${pkgs.papirus-icon-theme}/share/icons/*; do
      case ''${t##*/} in
        Papirus*) mkdir $out/share/icons/''${t##*/}
                  lndir -silent $t $out/share/icons/''${t##*/} ;;  # keeps its relative links (Dark → Papirus)
        *) cp -P $t $out/share/icons/ ;;   # breeze, hicolor: the themes Papirus falls back to
      esac
    done
    for p in $out/share/icons/*/*/places; do
      case "$p" in */16x16*/places) continue ;; esac
      case "$(readlink -f "$p")" in $out/*) ;; *) continue ;; esac
      for g in "$p"/*-grey.svg "$p"/*-grey-*.svg; do
        [ -e "$g" ] || continue
        b=''${g##*/}
        [ -e "$p/''${b/-grey/}" ] && ln -sf "$b" "$p/''${b/-grey/}"
      done
    done
    for t in $out/share/icons/Papirus*; do gtk-update-icon-cache --force --quiet "$t"; done
  '';
in
{
  environment.systemPackages = with pkgs; [
    foot libnotify
    # Mod+Shift+X (screenshot.sh ocr): wayfreeze stills the screen, slurp + grim grab, tesseract
    # reads it (only these languages, all of them is huge). Mod+Shift+R: wf-recorder (record.sh)
    grim slurp wayfreeze wf-recorder
    (tesseract.override { enableLanguages = [ "eng" "fra" "nld" ]; })
    # GUI utilities (nm-connection-editor: VPNs and what Noctalia's network panel doesn't show)
    pavucontrol networkmanagerapplet file-roller baobab eog evince adwaita-icon-theme
    bibata-cursors papirusGrey
    # Umbriel's cursor, included by ~/.config/umbriel/config.toml: its default (24) differs from
    # what apps draw
    (writeTextDir "share/umbriel/cursor.toml" ''
      [input.cursor]
      theme = "${cursorTheme}"
      size = ${toString cursorSize}
    '')
    adw-gtk3   # Mono-dark (~/.local/share/themes) imports its dark variant
    # The same default-apps list in share/applications, read through XDG_DATA_DIRS: sandboxes with
    # their own /etc (Claude Desktop's bwrap) never see /etc/xdg and opened links in Chromium
    (runCommand "mimeapps" { } ''
      install -Dm644 ${config.environment.etc."xdg/mimeapps.list".source} $out/share/applications/mimeapps.list
    '')
  ];

  # Not nm-applet (networkmanagerapplet's autostart): Noctalia has the network panel, its tray and the
  # Wi-Fi/802.1X password prompts. /etc/xdg comes first in XDG_CONFIG_DIRS, so Hidden here wins
  environment.etc."xdg/autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  environment.sessionVariables = {
    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString cursorSize;
    NIXOS_OZONE_WL = "1";    # Electron/Chromium on Wayland
  };

  # Keyring unlocked at login via PAM (greetd: Noctalia Greeter, noctalia.nix)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.polkit.enable = true;

  # File pickers and Flatpak integration next to Umbriel's own portal (screen sharing), which
  # noctalia.nix's Umbriel module adds
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };

  # ── Themes ──────────────────────────────────────────
  # Qt: Fusion with black and white palettes through qt6ct. darkmode.sh writes ~/.config/qt6ct/qt6ct.conf
  # (Qt's own gtk3 theme ignores the GTK colours and falls back to Adwaita's old greys)
  qt = {
    enable = true;
    platformTheme = "qt5ct";   # qt5ct + qt6ct; all Qt apps here are Qt6
  };
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = gtkTheme;
        cursor-theme = cursorTheme;
        icon-theme = iconTheme;
        cursor-size = lib.gvariant.mkInt32 cursorSize;
      };
    }];
  };
  # Mono-dark (~/.local/share/themes, tracked) imports ../../adw-gtk3-dark: link the system's here at
  # login. A link, not a tracked file: the tablet keeps a real adw-gtk3 at that path
  systemd.user.tmpfiles.rules = [ "L+ %h/.local/share/themes/adw-gtk3-dark - - - - /run/current-system/sw/share/themes/adw-gtk3-dark" ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
  ];

  # ── Default apps ────────────────────────────────────
  # ~/.config/mimeapps.list, which apps write to, still wins
  xdg.mime.defaultApplications =
    let each = app: types: lib.genAttrs types (_: app);
    in each "thunar.desktop" [ "inode/directory" ]
      // each "librewolf.desktop" [ "x-scheme-handler/http" "x-scheme-handler/https" "text/html" "application/xhtml+xml" ]
      // each "org.gnome.Evince.desktop" [ "application/pdf" ]
      // each "org.gnome.eog.desktop" (map (t: "image/${t}") [ "jpeg" "jpg" "png" "gif" "bmp" "webp" "tiff" ])
      // each "mpv.desktop" [ "video/mp4" "video/x-matroska" "video/webm" "video/quicktime" "video/x-msvideo"
                             "audio/mpeg" "audio/x-wav" "audio/flac" "audio/ogg" ]
      // each "helix.desktop" [ "text/plain" "text/x-c" "text/x-c++" "text/x-java" "text/x-python" "application/x-shellscript" ];

  # File manager + thumbnails, mounting, trash (yazi: packages.nix)
  programs.thunar = {
    enable = true;
    plugins = [ pkgs.thunar-archive-plugin ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
