{
  config,
  pkgs,
  inputs,
  xlib,
  ...
}:
{
  xdg = {
    dataFile = {
      "PrismLauncher" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.soptur-drive}/Games/PrismLauncher";
        target = "PrismLauncher";
      };
    };
  };
  home.file = {
    "Storage" = {
      source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.vetymae-drive}/Users/oqyude/Storage";
      target = "Storage";
    };
    "Music" = {
      source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.vetymae-drive}/Users/oqyude/Music";
      target = "Music";
    };
    "Misc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.vetymae-drive}/Users/oqyude/Misc";
      target = "Misc";
    };
    "Vaults" = {
      source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.vetymae-drive}/Users/oqyude/Vaults";
      target = "Vaults";
    };
  };
}
