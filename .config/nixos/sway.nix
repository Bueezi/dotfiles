# The desktop session: SwayFX and its tools, login, screen sharing, themes, default apps, fonts.
# Sway's own config is ~/.config/wm/sway
{ config, lib, pkgs, ... }:

let
  # Cursor and icon themes for sway (XCURSOR_*), GTK and dconf below. To revert: "Adwaita" for both
  # (and `seat * xcursor_theme` in the sway config)
  cursorTheme = "Bibata-Modern-Classic";
  cursorSize = 20;   # also in `seat * xcursor_theme` in the sway config
  # Dark is the default; darkmode.sh ($mod+Shift+t) switches to adw-gtk3 / Papirus and back
  iconTheme = "Papirus-Dark";   # grey folders instead of blue (papirusGrey below)
  gtkTheme = "Mono-dark";   # adw-gtk3-dark in black: ~/.local/share/themes/Mono-dark (a real file)

  # swaylock-effects only starts redrawing on its first clock tick (~1s after locking), so the
  # fade-in sits on the unblurred screenshot until then. Start redrawing once the lock surface
  # is configured, so the fade begins immediately.
  swaylockFx = pkgs.swaylock-effects.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i '/ext_session_lock_surface_v1_ack_configure(lock_surface, serial);/{n;n;s/$/\n\tdamage_surface(surface);/}' main.c
      grep -A3 'ext_session_lock_surface_v1_ack_configure(lock_surface, serial);' main.c | grep -q damage_surface
    '';
  });

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
  # ── Sway ────────────────────────────────────────────
  programs.sway = {
    enable = true;
    package = pkgs.swayfx; # latest git via swayfx.nix (no HDR: scenefx renderer)
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export QT_QPA_PLATFORM="wayland;xcb"
      # Proton's native Wayland: per game (launch option `PROTON_ENABLE_WAYLAND=1 %command%`), not for
      # all of them. No PROTON_ENABLE_HDR: swayfx has no HDR output
    '';
    extraPackages = with pkgs; [
      # session
      swaylockFx swayidle awww wdisplays wlsunset lxqt.lxqt-policykit
      # terminal, launcher, bar, notifications
      foot fuzzel i3status-rust mako libnotify swayr bzmenu
      # clipboard picker (fzf + sixel image preview) and auto-paste
      fzf chafa wtype
      # screenshots, recording, clipboard
      grim slurp wayfreeze wf-recorder cliphist
      # OCR ($mod+Shift+x, screenshot.sh ocr): only these languages, all of them is huge
      (tesseract.override { enableLanguages = [ "eng" "fra" "nld" ]; })
      # hardware controls, media keys (osd.sh)
      brightnessctl playerctl pavucontrol
      networkmanager_dmenu networkmanagerapplet
      # GUI utilities
      file-roller baobab eog evince adwaita-icon-theme
      bibata-cursors papirusGrey
      adw-gtk3   # Mono-dark (~/.local/share/themes) imports its dark variant
    ];
  };

  environment.sessionVariables = {
    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString cursorSize;
    NIXOS_OZONE_WL = "1";    # Electron/Chromium on Wayland
  };

  # ── Login ───────────────────────────────────────────
  # greetd + tuigreet, black and white with a big "nixos" greeting. Sway gets its config's real
  # path (-c), so ~/.config/sway/config isn't needed
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = let
        greeting = lib.concatStringsSep "\n" [   # lines padded to one width: tuigreet centres each
        "          _                "
        "   ____  (_)  ______  _____"
        "  / __ \\/ / |/_/ __ \\/ ___/"
        " / / / / />  </ /_/ (__  ) "
        "/_/ /_/_/_/|_|\\____/____/  "
        ];
      in "${pkgs.writeShellScript "tuigreet" ''
        exec ${pkgs.tuigreet}/bin/tuigreet --cmd 'sway -c /home/ben/.config/wm/sway' --remember --asterisks \
          --time --time-format '%a %d/%m  %H:%M' \
          --greeting '${greeting}' --window-padding 2 --container-padding 2 \
          --theme 'border=white;text=gray;prompt=white;time=gray;action=darkgray;button=white;container=black;input=white;greet=white'
      ''}";
      user = "greeter";
    };
  };

  # Keyring unlocked at login via PAM
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  # swaylock: no ~2s pause after a wrong password (pam_unix's default). swaylock ignores keys
  # while it checks, so you had to wait before retyping; now a wrong one is rejected at once
  security.pam.services.swaylock.nodelay = true;
  security.polkit.enable = true;

  # Screen sharing, file pickers, Flatpak integration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # Screen-share picker (screens + windows). Full path: the portal service's PATH doesn't
    # include the sway packages, and NixOS ignores ~/.config/xdg-desktop-portal-wlr/config.
    wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${lib.getExe pkgs.fuzzel} --dmenu --prompt 'share ❯ '";
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
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
  # The same list in share/applications, read through XDG_DATA_DIRS: sandboxes with their own /etc
  # (Claude Desktop's bwrap) never see /etc/xdg and opened links in Chromium
  environment.systemPackages = [
    (pkgs.runCommand "mimeapps" { } ''
      install -Dm644 ${config.environment.etc."xdg/mimeapps.list".source} $out/share/applications/mimeapps.list
    '')
  ];

  # File manager + thumbnails, mounting, trash
  programs.thunar = {
    enable = true;
    plugins = [ pkgs.thunar-archive-plugin ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
