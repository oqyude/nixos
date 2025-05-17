{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg = {
    enable = true;
    autostart.enable = true;
    configFile = {
      "beets" = {
        source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/beets/linux";
        target = "beets";
      };
    };
  };
}
