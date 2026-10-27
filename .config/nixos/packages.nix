# Apps and command-line tools on both machines. Development: dev.nix; one machine only: desktop.nix,
# gaming.nix; the session's own tools: sway.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # CLI
    git gh gcc python3 less htop btop powertop fastfetch cowsay
    wl-clipboard zip unzip p7zip ffmpeg jq wl-mirror
    starship  # prompt, ~/.config/starship.toml
    cava cmatrix pipes  # music visualiser (~/.config/cava/config), eye candy
    freerdp   # RDP into Windows: sdl-freerdp /v:<ip> /u:<user> /dynamic-resolution
    man-pages man-pages-posix # man
    nvd   # rb: what each rebuild changed
    # Apps
    librewolf ungoogled-chromium mpv vesktop qbittorrent
    libreoffice bazaar gearlever
    # Claude Desktop (community build; updates to the latest version on rebuild)
    (builtins.getFlake "github:aaddrick/claude-desktop-debian").packages.${stdenv.hostPlatform.system}.default
    # fetch by areofyl: spinning 3D distro logo + system info (not in 26.05 yet; built with the
    # system nixpkgs). Pinned: newer = a newer rev + its hash (nix-prefetch-url --unpack <url>, then
    # nix hash convert --hash-algo sha256 <it>). Logo in colour, grey usage percentages.
    # The tablet builds the same commit (termux.sh, fetch_commit): change both together
    ((callPackage "${builtins.fetchTarball {
      url = "https://github.com/areofyl/fetch/archive/e3087810e2a131ed4093440e783ac96a101ad806.tar.gz";
      sha256 = "sha256-hgoTIBD2pvZDJxefMz+g8ALs4lqsMHOPHH4wwiomsaA=";
    }}/nix/package.nix" { }).overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' fetch.c'';
    }))
  ];
}
