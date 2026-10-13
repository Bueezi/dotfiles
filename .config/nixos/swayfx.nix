# Latest swayfx from git, see ./swayfx/flake.nix (pinned in its flake.lock).
{ ... }:

{
  nixpkgs.overlays = [ (builtins.getFlake (toString ./swayfx)).overlays.default ];
}
