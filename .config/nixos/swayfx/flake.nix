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
      swayfx-unwrapped = (prev.swayfx-unwrapped.override { wlroots_0_19 = final.wlroots_0_20; }).overrideAttrs (old: {
        version = "git-${swayfx.shortRev}";
        src = swayfx;
        # Close animation crash (github.com/wlrfx/swayfx/issues/557): a window hidden and shown again
        # quickly gets a new container while the old one still animates out. The new one drops the
        # view's saved buffer, so the old animation's end found none and the assert killed sway.
        # Only touch it if the view is still ours. --replace-fail: the build breaks once upstream
        # changes this line, time to check whether #557 is fixed and drop this.
        postPatch = (old.postPatch or "") + ''
          substituteInPlace sway/desktop/transaction.c --replace-fail \
            'view_remove_saved_buffer(con->view);' \
            'if (con->view->container == con && con->view->saved_surface_tree) view_remove_saved_buffer(con->view);'
        '';
      });
    };
  };
}
