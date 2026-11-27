# Pins for what follows main (noctalia.nix, packages.nix); `rb -u` updates the lock
{
  inputs = {
    umbriel = { url = "github:noctalia-dev/umbriel";                    flake = false; };
    portal  = { url = "github:noctalia-dev/xdg-desktop-portal-umbriel"; flake = false; };
    claude-desktop = { url = "github:aaddrick/claude-desktop-debian";      flake = false; };
    fetch   = { url = "github:areofyl/fetch";                           flake = false; };
  };

  outputs = _: { };
}
