# Update: nix flake update --flake ~/.config/nix/noctalia && rb (new releases: bump the tags)
{
  inputs = {
    noctalia = { url = "github:noctalia-dev/noctalia/v5.4.1";            flake = false; };
    umbriel  = { url = "github:noctalia-dev/umbriel";                    flake = false; };
    portal   = { url = "github:noctalia-dev/xdg-desktop-portal-umbriel"; flake = false; };
    greeter  = { url = "github:noctalia-dev/noctalia-greeter/v1.7.0";     flake = false; };
    # Umbriel needs >= 0.20.1 (26.05 has 0.20.0); for Umbriel only, an overlay rebuilds the rest
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

    nixosModules = {
      noctalia = "${noctalia}/nix/nixos-module.nix";
      greeter = "${greeter}/nix/nixos-module.nix";
      umbriel = import "${umbriel}/nix/nixos-module.nix" { xdg-desktop-portal-umbriel = null; };
    };
  };
}
