{
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [ (import ../overlays/immich) ];
}
