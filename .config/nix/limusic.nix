{ pkgs, ... }:

let
  limusic = pkgs.stdenv.mkDerivation rec {
    pname = "limusic";
    version = "1.4.0";
    # Update: new version, then nix-prefetch-url <url>
    src = pkgs.fetchurl {
      url = "https://github.com/SimoHypers/limusic/releases/download/v${version}/limusic_${version}_amd64.deb";
      sha256 = "1qw8lilzwzyrxfj3wdxcq4g1sswj0xbp1vs0gs0avisjf0zn7gjv";
    };
    nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook wrapGAppsHook3 ];
    buildInputs = with pkgs; [ mpv-unwrapped gtk3 webkitgtk_4_1 libsoup_3 dbus glib-networking ];
    installPhase = ''
      mkdir -p $out
      cp -r usr/* $out/
    '';
    # Tray icon (dlopened)
    preFixup = ''
      gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.libayatana-appindicator ]})
    '';
  };
in
{
  environment.systemPackages = [ limusic ];
}
