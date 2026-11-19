# Updated by `rb -u` (nix flake update --flake ~/.config/nix/noctalia)
{
  inputs = {
    umbriel = { url = "github:noctalia-dev/umbriel";                    flake = false; };
    portal  = { url = "github:noctalia-dev/xdg-desktop-portal-umbriel"; flake = false; };
  };

  outputs = { umbriel, portal, ... }: {
    overlays.default = final: prev: {
      umbriel = final.callPackage "${umbriel}/nix/package.nix" { rev = umbriel.shortRev; };
      xdg-desktop-portal-umbriel = final.callPackage "${portal}/nix/package.nix" { };
    };

    nixosModules.umbriel = import "${umbriel}/nix/nixos-module.nix" { xdg-desktop-portal-umbriel = null; };
  };
}
