# Shared NixOS config for the laptop and the desktop.
# Imported by the stub in ~/.config/scripts/configuration.nix (which lives in /etc/nixos on each
# machine); per-machine settings (hostName, isLaptop) are set there.
{ config, lib, pkgs, isLaptop, ... }:

let
  # Cursor and icon themes for sway (XCURSOR_*), GTK and dconf below. To revert: "Adwaita" for both
  # (and `seat * xcursor_theme` in the sway config)
  cursorTheme = "Bibata-Modern-Classic";
  cursorSize = 20;   # also in `seat * xcursor_theme` in the sway config
  # Dark is the default; darkmode.sh ($mod+Shift+t) switches to Mono / Papirus and back
  iconTheme = "Papirus-Dark";   # grey folders instead of blue (papirus override below)
  gtkTheme = "Mono-dark";

  # GTK3 themes: adw-gtk3 (GTK3 in libadwaita's look) in black and white, no blue accent.
  # Dark has pure black backgrounds instead of Adwaita's grey. GTK4/libadwaita gets the same
  # from ~/.config/gtk-4.0/gtk.css, Qt from the qt6ct palettes in ~/.config/qt6ct/colors.
  mono = name: base: colors: pkgs.writeTextDir "share/themes/${name}/gtk-3.0/gtk.css" ''
    @import url("${pkgs.adw-gtk3}/share/themes/${base}/gtk-3.0/gtk.css");
    ${colors}
  '';
  monoThemes = [
    (mono "Mono" "adw-gtk3" ''
      @define-color accent_bg_color #1a1a1a;
      @define-color accent_fg_color white;
      @define-color accent_color #1a1a1a;
    '')
    (mono "Mono-dark" "adw-gtk3-dark" ''
      @define-color accent_bg_color white;
      @define-color accent_fg_color black;
      @define-color accent_color white;
      @define-color window_bg_color black;
      @define-color view_bg_color black;
      @define-color headerbar_bg_color black;
      @define-color headerbar_backdrop_color black;
      @define-color sidebar_bg_color #0a0a0a;
      @define-color sidebar_backdrop_color #0a0a0a;
      @define-color card_bg_color rgba(255, 255, 255, 0.05);
      @define-color dialog_bg_color #111111;
      @define-color popover_bg_color #111111;
      @define-color thumbnail_bg_color #111111;
    '')
  ];

  # swaylock-effects only starts redrawing on its first clock tick (~1s after locking), so the
  # fade-in sits on the unblurred screenshot until then. Start redrawing once the lock surface
  # is configured, so the fade begins immediately.
  swaylockFx = pkgs.swaylock-effects.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i '/ext_session_lock_surface_v1_ack_configure(lock_surface, serial);/{n;n;s/$/\n\tdamage_surface(surface);/}' main.c
      grep -A3 'ext_session_lock_surface_v1_ack_configure(lock_surface, serial);' main.c | grep -q damage_surface
    '';
  });
in
{
  # Optional extras from the dotfiles repo, skipped on a fresh install (no dotfiles yet)
  imports = builtins.filter builtins.pathExists [
    /home/ben/.config/nixos/librewolf.nix
    /home/ben/.config/nixos/swayfx.nix  # latest swayfx from git
    /home/ben/.config/nixos/plymouth.nix  # boot splash (penguin video)
    /home/ben/.config/nixos/eclipse.nix   # Eclipse Music as a desktop app
    /home/ben/.config/nixos/hyprquickpaper.nix  # wallpaper picker ($mod+Shift+w)
  ];

  # ── Boot ────────────────────────────────────────────
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 3;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest; # RDNA4 needs a recent kernel
  };

  # Switch profile automatically on AC/battery
  services.udev.extraRules = lib.mkIf isLaptop ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
  '';

  # Don't power the Bluetooth radio until you need it
  hardware.bluetooth.powerOnBoot = !isLaptop;

  # Laptop's Realtek (rtw89) Wi-Fi card fix
  networking.networkmanager.wifi.powersave = lib.mkIf isLaptop false;

  boot.extraModprobeConfig = lib.mkIf isLaptop ''
    options rtw89_core disable_ps_mode=y
    options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y disable_clkreq=y
  '';

  # ── System basics ───────────────────────────────────
  networking.networkmanager.enable = true;

  services.printing.enable = true;
  services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };

  time.timeZone = "Europe/Brussels";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";

  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    extraGroups = [ "networkmanager" "wheel" "video" ] ++ lib.optional (!isLaptop) "i2c";
  };

  # Git identity, system-wide (/etc/gitconfig)
  programs.git = {
    enable = true;
    config = {
      user = { name = "Bueezi"; email = "mail@b3n.me"; };
      core.editor = "hx";
    };
  };

  # Shells: bash stays the login shell (and for scripts); foot starts fish (~/.config/fish)
  programs.fish.enable = true;
  # NixOS has no /bin/bash, so scripts with `#!/bin/bash` fail; point it at the system bash
  systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash" ]
    # LM Studio keeps its models etc. in ~/.lmstudio: point that at the nvme
    ++ lib.optionals (!isLaptop) [ "L /home/ben/.lmstudio - - - - /mnt/nvme/Documents/lm-studio" ];

  zramSwap.enable = true;

  # ── Hardware ────────────────────────────────────────
  hardware = {
    graphics = { enable = true; enable32Bit = true; };
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    bluetooth.enable = true;
  };

  services.fwupd.enable = true;
  services.blueman.enable = true;

  # RAM RGB: OpenRGB reaches the DIMMs over SMBus through /dev/i2c-* (i2c-dev).
  # spd5118 (DDR5 SPD/temperature driver) claims the sticks' SPD addresses, which makes
  # OpenRGB skip them, so keep it off (costs the RAM temperature sensor).
  boot.kernelModules = lib.optionals (!isLaptop) [ "i2c-dev" ];
  boot.blacklistedKernelModules = lib.optionals (!isLaptop) [ "spd5118" ];
  # /dev/i2c-* for the i2c group too: ddcutil sets the monitor's brightness over DDC/CI
  hardware.i2c.enable = !isLaptop;

  systemd.services.rgb-off = lib.mkIf (!isLaptop) {
    description = "Turn off RGB lighting";
    wantedBy = [ "multi-user.target" "suspend.target" ];
    after = [ "systemd-modules-load.service" "suspend.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.openrgb}/bin/openrgb --noautoconnect -m off";
    };
  };

  # ── Audio ───────────────────────────────────────────
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = { enable = true; support32Bit = true; };
    pulse.enable = true;
  };

  # ── Power ───────────────────────────────────────────
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Idle is handled by swayidle in the sway config.
  services.logind.settings.Login.HandleLidSwitch = lib.mkIf isLaptop "suspend-then-hibernate";

  # Laptop: how long to sleep before switching to hibernate
  systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkIf isLaptop "30min";
  boot.resumeDevice = lib.mkIf isLaptop "/dev/disk/by-uuid/8ac0d876-3d7b-485a-8948-4ccd737b8d5f";

  fileSystems."/mnt/nvme" = lib.mkIf (!isLaptop) {
    device = "/dev/disk/by-uuid/b2eb90c5-7585-4519-83e9-91808d894f17";   # from `blkid /dev/nvme0n1p3`
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=5s" "x-gvfs-show" "x-gvfs-name=nvme" ];
  };
  fileSystems."/mnt/hdd" = lib.mkIf (!isLaptop) {
    device = "/dev/disk/by-uuid/005AA8F65AA8EA1C";
    fsType = "ntfs3";   # the kernel's own NTFS driver, faster than ntfs-3g
    options = [
      "nofail" "x-systemd.device-timeout=5s"
      "uid=1000" "gid=100" "umask=022"   # NTFS has no Linux owners: make everything yours
      "x-gvfs-show" "x-gvfs-name=hdd"
    ];
  };

  # ── Desktop: Sway ───────────────────────────────────
  programs.sway = {
    enable = true;
    package = pkgs.swayfx; # latest git via ~/.config/nixos/swayfx (no HDR: scenefx renderer)
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export QT_QPA_PLATFORM="wayland;xcb"
      # Proton: native Wayland and HDR in games
      export PROTON_ENABLE_WAYLAND=1
      export PROTON_ENABLE_HDR=1
    '';
    extraPackages = with pkgs; [
      # session
      swaylockFx swayidle swaybg awww wdisplays kanshi wlsunset lxqt.lxqt-policykit
      # terminal, launcher, bar, notifications
      foot fuzzel i3status-rust mako libnotify swayr bzmenu 
      # clipboard picker (fzf + sixel image preview) and auto-paste
      fzf chafa wtype
      # screenshots, recording, clipboard
      grim slurp wayfreeze wf-recorder cliphist
      # hardware controls (pulseaudio only for `pactl`)
      brightnessctl pulseaudio pavucontrol
      networkmanager_dmenu networkmanagerapplet
      # GUI utilities
      file-roller baobab eog adwaita-icon-theme
      bibata-cursors (papirus-icon-theme.override { color = "grey"; })
    ] ++ monoThemes;
  };

  environment.sessionVariables = {
    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString cursorSize;
    NIXOS_OZONE_WL = "1";    # Electron/Chromium on Wayland
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";   # std sources for rust-analyzer
  };

  # Login: greetd + tuigreet, black and white with a big "nixos" greeting
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
        exec ${pkgs.tuigreet}/bin/tuigreet --cmd sway --remember --asterisks \
          --time --time-format '%a %d/%m  %H:%M' \
          --greeting '${greeting}' --window-padding 2 --container-padding 2 \
          --theme 'border=white;text=gray;prompt=white;time=gray;action=darkgray;button=white;container=black;input=white;greet=white'
      ''}";
      user = "greeter";
    };
  };

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

  security.polkit.enable = true;
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
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${gtkTheme}
    gtk-cursor-theme-name=${cursorTheme}
    gtk-icon-theme-name=${iconTheme}
    gtk-cursor-theme-size=${toString cursorSize}
  '';

  # Default apps (was default.sh). ~/.config/mimeapps.list, which apps write to, still wins.
  xdg.mime.defaultApplications =
    let each = app: types: lib.genAttrs types (_: app);
    in each "thunar.desktop" [ "inode/directory" ]
      // each "librewolf.desktop" [ "x-scheme-handler/http" "x-scheme-handler/https" "text/html" "application/xhtml+xml" "application/pdf" ]
      // each "org.gnome.eog.desktop" (map (t: "image/${t}") [ "jpeg" "jpg" "png" "gif" "bmp" "webp" "tiff" ])
      // each "mpv.desktop" [ "video/mp4" "video/x-matroska" "video/webm" "video/quicktime" "video/x-msvideo"
                             "audio/mpeg" "audio/x-wav" "audio/flac" "audio/ogg" ]
      // each "helix.desktop" [ "text/plain" "text/x-c" "text/x-c++" "text/x-java" "text/x-python" "application/x-shellscript" ];

  # Keyring unlocked at login via PAM
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # File manager + thumbnails, mounting, trash
  programs.thunar = {
    enable = true;
    plugins = [ pkgs.thunar-archive-plugin ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
  ];

  # ── Nix & containers ────────────────────────────────
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
    # Extra libraries AppImages expect in /usr/lib
    package = pkgs.appimage-run.override {
      # Nuvio's player bridge (libplayer_bridge.so) needs libmpv.so.2 and webkit2gtk-4.1
      extraPkgs = pkgs: [ pkgs.mpv-unwrapped pkgs.webkitgtk_4_1 ];
    };
  };
  services.flatpak.enable = true;

  # ── Packages ────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # CLI
    git gh gcc python3 less htop btop powertop fastfetch cowsay
    wl-clipboard zip unzip p7zip ffmpeg jq wl-mirror
    starship  # prompt, ~/.config/starship.toml
    cava cmatrix pipes  # music visualiser (~/.config/cava/config), eye candy
    freerdp   # RDP into Windows: sdl-freerdp /v:<ip> /u:<user> /dynamic-resolution
    man-pages man-pages-posix # man
    # Dev
    # Helix opens in foot from file managers (text/* defaults above)
    (makeDesktopItem {
      name = "helix"; desktopName = "Helix"; exec = "foot hx %F";
      mimeTypes = [ "text/plain" ]; categories = [ "Development" "TextEditor" ];
    })
    neovim helix vscode nodejs rustc cargo podman-compose sqlite-interactive dbeaver-bin
    distrobox distroshelf
    # KUL
    (texliveBasic.withPackages (ps: with ps; [ collection-latex collection-latexrecommended collection-fontsrecommended collection-fontsextra collection-latexextra collection-langeuropean latexmk ])) ddd gdb openssl
    # LSP (Helix, ~/.config/helix/languages.toml): Python, C/C++, HTML/CSS/JSON, JS/TS, Tailwind,
    # Rust, shell (+ shellcheck), PHP, SQL, Nix
    basedpyright clang-tools vscode-langservers-extracted typescript-language-server typescript
    tailwindcss-language-server rust-analyzer bash-language-server shellcheck intelephense sqls nil
    # Apps
    librewolf ungoogled-chromium mpv vesktop qbittorrent
    libreoffice filezilla github-desktop bazaar gearlever
    # Claude Desktop (community build; updates to the latest version on rebuild)
    (builtins.getFlake "github:aaddrick/claude-desktop-debian").packages.${stdenv.hostPlatform.system}.default
    # fetch by areofyl: spinning 3D distro logo + system info (not in 26.05 yet; follows main,
    # built with the system nixpkgs). Black and white: no logo colours, grey usage percentages.
    ((callPackage "${builtins.fetchTarball "https://github.com/areofyl/fetch/archive/main.tar.gz"}/nix/package.nix" { }).overrideAttrs (old: {
      postPatch = ''sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' fetch.c'';
      postInstall = old.postInstall + "wrapProgram $out/bin/fetch --add-flags --no-color";
    }))
  ]
  # ── Per-machine apps ────────────────────────────────
  # Packages installed on only one machine. (Apps that need a NixOS module, like
  # Steam, go in the "Gaming" section below instead.)
  ++ lib.optionals (!isLaptop) [ # desktop only
    upscayl               # AI image upscaler
    openrgb               # RGB control GUI/CLI (rgb-off below uses its own store path)
    rocmPackages.rocm-smi # GPU monitoring
    mangohud              # in-game FPS/temps overlay: `mangohud %command%` in Steam
    protontricks          # Windows fonts/libs into a game's Proton prefix (Content Manager)
    oversteer             # G920 settings: rotation, force feedback, pedal test
    ddcutil               # monitor brightness over DDC/CI (osd.sh brightness)
    lmstudio              # local LLMs; data/models live on the nvme (see tmpfiles above)
  ]
  ++ lib.optionals isLaptop [   # laptop only
  ];

  # ── Gaming (desktop only) ───────────────────────────
  programs.steam = lib.mkIf (!isLaptop) {
    enable = true;
    remotePlay.openFirewall = true;               # Steam Remote Play
    localNetworkGameTransfers.openFirewall = true; # copy games between PCs on the LAN
    extraCompatPackages = [ pkgs.proton-ge-bin ];  # Proton-GE, pick it per game in Properties > Compatibility
  };
  # Performance mode while a game runs: launch option `gamemoderun %command%`
  programs.gamemode.enable = !isLaptop;
  # Micro-compositor for games: HDR, frame limiting, upscaling (`gamescope --hdr-enabled -- %command%`)
  # (No capSysNice: its capability wrapper can't run inside Steam's sandbox, so gamescope
  # fails with "failed to inherit capabilities" and the game exits)
  programs.gamescope.enable = !isLaptop;
  # GPU control (fan curves, power limit, undervolt): LACT app + its daemon
  services.lact.enable = !isLaptop;
  # Logitech G920: switch it out of Xbox mode so it shows up as a wheel
  hardware.usb-modeswitch.enable = !isLaptop;
  # Let Oversteer and OpenRGB reach the wheel / RGB devices without root
  services.udev.packages = lib.mkIf (!isLaptop) [ pkgs.oversteer pkgs.openrgb ];

  system.stateVersion = "26.05";
}
