{
  config,
  pkgs,
  inputs,
  xlib,
  ...
}:
let
  symlinksPaths = {
    "${xlib.dirs.soptur-drive}/Games/PrismLauncher" = ".local/share/PrismLauncher";
    "${xlib.dirs.vetymae-drive}/Users/oqyude/Storage" = "Storage";
    "${xlib.dirs.vetymae-drive}/Users/oqyude/Music" = "Music";
    "${xlib.dirs.vetymae-drive}/Users/oqyude/Misc" = "Misc";
    "${xlib.dirs.vetymae-drive}/Users/oqyude/Vaults" = "Vaults";
  };
  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;
in
{
  home.file = mkLinks;
}
