{ config, lib, pkgs, ... }:

let
  cursorTheme = "Bibata-Modern-Classic";
  cursorSize = 20;   # also in ~/.config/gtk-3.0/settings.ini
  iconTheme = "Papirus-Dark";
  gtkTheme = "Mono-dark";

  # Grey folders by linking, not papirus-folders' override, which rebuilt ~80k icons on every update
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
    grim slurp wayfreeze wf-recorder
    (tesseract.override { enableLanguages = [ "eng" "fra" "nld" ]; })
    networkmanagerapplet eog evince adwaita-icon-theme
    bibata-cursors papirusGrey
    # yazi's own entry is Terminal=true, and GLib doesn't know foot
    (makeDesktopItem {
      name = "yazi-foot"; desktopName = "Yazi"; exec = "foot --app-id=yazi yazi %f"; noDisplay = true;
      mimeTypes = [ "inode/directory" ];
    })
    (writeTextDir "share/umbriel/cursor.toml" ''
      [input.cursor]
      theme = "${cursorTheme}"
      size = ${toString cursorSize}
    '')
    adw-gtk3
    # For sandboxes without /etc/xdg (Claude Desktop's bwrap opened links in Chromium)
    (runCommand "mimeapps" { } ''
      install -Dm644 ${config.environment.etc."xdg/mimeapps.list".source} $out/share/applications/mimeapps.list
    '')
  ];

  # Noctalia does the network panel and prompts
  environment.etc."xdg/autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  environment.sessionVariables = {
    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString cursorSize;
    NIXOS_OZONE_WL = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";   # Java apps (Nuvio) drew a white edge on Xwayland
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.passwd.enableGnomeKeyring = true;   # keeps the keyring's password in sync

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  qt = {
    enable = true;
    platformTheme = "qt5ct";   # qt6ct palettes; darkmode.sh writes qt6ct.conf
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
  # Mono-dark imports ../../adw-gtk3-dark
  systemd.user.tmpfiles.rules = [ "L+ %h/.local/share/themes/adw-gtk3-dark - - - - /run/current-system/sw/share/themes/adw-gtk3-dark" ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
  ];

  xdg.mime.defaultApplications =
    let each = app: types: lib.genAttrs types (_: app);
    in each "yazi-foot.desktop" [ "inode/directory" ]
      // each "librewolf.desktop" [ "x-scheme-handler/http" "x-scheme-handler/https" "text/html" "application/xhtml+xml" ]
      // each "org.gnome.Evince.desktop" [ "application/pdf" ]
      // each "org.gnome.eog.desktop" (map (t: "image/${t}") [ "jpeg" "jpg" "png" "gif" "bmp" "webp" "tiff" ])
      // each "mpv.desktop" [ "video/mp4" "video/x-matroska" "video/webm" "video/quicktime" "video/x-msvideo"
                             "audio/mpeg" "audio/x-wav" "audio/flac" "audio/ogg" ]
      // each "helix.desktop" [ "text/plain" "text/x-c" "text/x-c++" "text/x-java" "text/x-python" "application/x-shellscript" ];

  services.gvfs.enable = true;
}
