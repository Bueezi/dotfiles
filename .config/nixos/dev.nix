# Development: editors, compilers, language servers, containers, adb, KU Leuven's LaTeX.
# Editors' own settings: ~/.config/helix, ~/.config/VSCodium (its extensions installed by rb)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Helix opens in foot from file managers (text/* defaults in session.nix)
    (makeDesktopItem {
      name = "helix"; desktopName = "Helix"; exec = "foot hx %F";
      mimeTypes = [ "text/plain" ]; categories = [ "Development" "TextEditor" ];
    })
    # Zed (`zeditor`), FHS variant: the language servers and extensions it downloads are generic
    # Linux binaries that need a normal /usr/lib
    zed-editor.fhs
    # GitHub sign-in in the keyring: Electron doesn't know "umbriel" (see Claude in packages.nix)
    (vscodium.override { commandLineArgs = "--password-store=gnome-libsecret"; })
    helix nodejs rustc cargo podman-compose sqlite-interactive
    distrobox distroshelf
    android-tools
    # Android Studio comes from tolly's flake (~/Documents/tolly), pinned there so rebuilds don't fetch
    # it. --profile keeps it from the daily garbage collection
    (makeDesktopItem {
      name = "android-studio"; desktopName = "Android Studio"; icon = "android-studio";
      categories = [ "Development" "IDE" ];
      exec = "${writeShellScript "android-studio-tolly" ''
        cd ~/Documents/tolly && exec nix develop --profile ~/.cache/nix/tolly-dev -c android-studio "$@"
      ''}";
    })
    # KUL
    (texliveBasic.withPackages (ps: with ps; [ collection-latex collection-latexrecommended collection-fontsrecommended collection-fontsextra collection-latexextra collection-langeuropean latexmk ])) ddd gdb openssl
    lldb   # lldb-dap: Helix's debugger for C/C++/Rust (Space+G)
    # LSP (Helix, ~/.config/helix/languages.toml): Python, C/C++, HTML/CSS/JSON (+ Emmet), JS/TS, Tailwind,
    # Rust, shell (+ shellcheck), PHP, SQL, Nix, LaTeX, TOML, YAML, Markdown
    basedpyright clang-tools vscode-langservers-extracted typescript-language-server typescript
    tailwindcss-language-server emmet-language-server rust-analyzer bash-language-server shellcheck intelephense sqls nil
    texlab taplo yaml-language-server marksman
    # JS formatter: only adds semicolons (~/.config/helix/semi.mjs)
    eslint
  ];

  environment.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";   # std sources for rust-analyzer
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
