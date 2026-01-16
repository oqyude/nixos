{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  symlinksPaths = {
    "${xlib.dirs.lamet-drive}/Games/PrismLauncher" = ".local/share/PrismLauncher";
    "${xlib.dirs.lamet-drive}/Users/oqyude/Storage" = "Storage";
    "${xlib.dirs.lamet-drive}/Users/oqyude/Music" = "Music";
    "${xlib.dirs.lamet-drive}/Users/oqyude/Misc" = "Misc";
    "${xlib.dirs.lamet-drive}/Users/oqyude/Vaults" = "Vaults";
    "${xlib.dirs.lamet-drive}/Users/oqyude/Credentials" = "Credentials";
  };
  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;
in
{
  home.file = mkLinks;
}
