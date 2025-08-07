{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/beets
    ../server/open-webui.nix
  ];
}
