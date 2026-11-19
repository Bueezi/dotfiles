# Only pins Umbriel + portal for noctalia.nix; `rb -u` updates the lock
{
  inputs = {
    umbriel = { url = "github:noctalia-dev/umbriel";                    flake = false; };
    portal  = { url = "github:noctalia-dev/xdg-desktop-portal-umbriel"; flake = false; };
  };

  outputs = _: { };
}
