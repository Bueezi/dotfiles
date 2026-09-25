# Latest swayfx (git) built against the system's nixpkgs, so mesa/wlroots match the drivers.
# Versions are pinned in flake.lock; update with:
#   nix flake update --flake ~/.config/nixos/swayfx && sudo nixos-rebuild switch
{
  inputs = {
    swayfx  = { url = "github:WillPower3309/swayfx"; flake = false; };
    scenefx = { url = "github:wlrfx/scenefx";        flake = false; };
  };

  outputs = { swayfx, scenefx, ... }: {
    overlays.default = final: prev: {
      scenefx = (prev.scenefx.override { wlroots_0_19 = final.wlroots_0_20; }).overrideAttrs (old: {
        version = "git-${scenefx.shortRev}";
        src = scenefx;
        patches = [ ];
        buildInputs = old.buildInputs ++ [ final.lcms2 ];
      });
      swayfx-unwrapped = (prev.swayfx-unwrapped.override { wlroots_0_19 = final.wlroots_0_20; }).overrideAttrs {
        version = "git-${swayfx.shortRev}";
        src = swayfx;
      };
    };
  };
}
