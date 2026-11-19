{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (makeDesktopItem {
      name = "helix"; desktopName = "Helix"; exec = "foot hx %F";
      mimeTypes = [ "text/plain" ]; categories = [ "Development" "TextEditor" ];
    })
    zed-editor.fhs
    (vscodium.override { commandLineArgs = "--password-store=gnome-libsecret"; })
    helix nodejs rustc cargo podman-compose sqlite-interactive
    distrobox distroshelf
    android-tools
    # Pinned in ~/Documents/tolly's flake; --profile keeps it from garbage collection
    (makeDesktopItem {
      name = "android-studio"; desktopName = "Android Studio"; icon = "android-studio";
      categories = [ "Development" "IDE" ];
      exec = "${writeShellScript "android-studio-tolly" ''
        cd ~/Documents/tolly && exec nix develop --profile ~/.cache/nix/tolly-dev -c android-studio "$@"
      ''}";
    })
    (texliveBasic.withPackages (ps: with ps; [ collection-latex collection-latexrecommended collection-fontsrecommended collection-fontsextra collection-latexextra collection-langeuropean latexmk ])) ddd gdb openssl
    lldb
    basedpyright clang-tools vscode-langservers-extracted typescript-language-server typescript
    tailwindcss-language-server emmet-language-server rust-analyzer bash-language-server shellcheck intelephense sqls nil
    texlab taplo yaml-language-server marksman
    eslint
  ];

  environment.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
