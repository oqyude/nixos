{
  config,
  pkgs,
  inputs,
  xlib,
  ...
}:
{
  home.file = {
    "Storage" = {
      source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.vetymae-drive}/Users/oqyude/Storage";
      target = "Storage";
    };
  };
}
