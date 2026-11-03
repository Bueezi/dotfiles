# Noctalia and its greeter (latest releases) + Umbriel (git, no releases yet) built against the
# system's nixpkgs, like ../swayfx. Versions are pinned in flake.lock; update with:
#   nix flake update --flake ~/.config/nixos/noctalia && rb
# (bump the noctalia/greeter tags below for a new release)
{
  inputs = {
    noctalia = { url = "github:noctalia-dev/noctalia/v5.4.1";            flake = false; };
    umbriel  = { url = "github:noctalia-dev/umbriel";                    flake = false; };
    portal   = { url = "github:noctalia-dev/xdg-desktop-portal-umbriel"; flake = false; };
    # nixpkgs 26.05 has 1.3.1; syncing the look from Noctalia needs 1.5+
    greeter  = { url = "github:noctalia-dev/noctalia-greeter/v1.7.0";     flake = false; };
    # Umbriel needs wlroots >= 0.20.1, nixpkgs 26.05 has 0.20.0. Only Umbriel gets this one:
    # an overlay of wlroots_0_20 would rebuild SwayFX too
    wlroots  = { url = "gitlab:wlroots/wlroots/0.20.2?host=gitlab.freedesktop.org"; flake = false; };
  };

  outputs = { noctalia, umbriel, portal, greeter, wlroots, ... }: {
    overlays.default = final: prev: {
      noctalia = final.callPackage "${noctalia}/nix/package.nix" { rev = noctalia.shortRev; };
      umbriel = final.callPackage "${umbriel}/nix/package.nix" {
        rev = umbriel.shortRev;
        wlroots_0_20 = prev.wlroots_0_20.overrideAttrs { version = "0.20.2"; src = wlroots; };
      };
      xdg-desktop-portal-umbriel = final.callPackage "${portal}/nix/package.nix" { };
      noctalia-greeter = final.callPackage "${greeter}/nix/package.nix" { };
    };

    # Upstream's modules. Umbriel's takes its portal flake: the package is set in ../noctalia.nix instead
    nixosModules = {
      noctalia = "${noctalia}/nix/nixos-module.nix";
      greeter = "${greeter}/nix/nixos-module.nix";
      umbriel = import "${umbriel}/nix/nixos-module.nix" { xdg-desktop-portal-umbriel = null; };
    };
  };
}
