# Development: editors, compilers, language servers, containers, Android, Lean, KU Leuven's LaTeX.
# Editors' own settings: ~/.config/helix, ~/.config/VSCodium (its extensions installed by rb)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Helix opens in foot from file managers (text/* defaults in sway.nix)
    (makeDesktopItem {
      name = "helix"; desktopName = "Helix"; exec = "foot hx %F";
      mimeTypes = [ "text/plain" ]; categories = [ "Development" "TextEditor" ];
    })
    # Zed (`zeditor`), FHS variant: the language servers and extensions it downloads are generic
    # Linux binaries that need a normal /usr/lib
    zed-editor.fhs vscodium
    helix nodejs rustc cargo podman-compose sqlite-interactive dbeaver-bin
    distrobox distroshelf
    android-studio android-tools   # Gradle's downloaded aapt2 runs through nix-ld (base.nix)
    gemini-cli-bin
    # Lean 4 (VSCodium's leanprover.lean4): elan's lean/lake, toolchains in ELAN_HOME (below), the
    # default one installed by rb. nixpkgs' elan patches the glibc toolchains it downloads for NixOS
    elan
    # KUL
    (texliveBasic.withPackages (ps: with ps; [ collection-latex collection-latexrecommended collection-fontsrecommended collection-fontsextra collection-latexextra collection-langeuropean latexmk ])) ddd gdb openssl
    # LSP (Helix, ~/.config/helix/languages.toml): Python, C/C++, HTML/CSS/JSON, JS/TS, Tailwind,
    # Rust, shell (+ shellcheck), PHP, SQL, Nix, LaTeX, TOML, YAML, Markdown
    basedpyright clang-tools vscode-langservers-extracted typescript-language-server typescript
    tailwindcss-language-server rust-analyzer bash-language-server shellcheck intelephense sqls nil
    texlab taplo yaml-language-server marksman
  ];

  environment.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";   # std sources for rust-analyzer
    ELAN_HOME = "$HOME/.local/share/elan";   # Lean toolchains, not ~/.elan (same path as the tablet)
  };

  nixpkgs.config.android_sdk.accept_license = true;   # Android Studio's SDK

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
