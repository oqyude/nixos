{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  symlinksPaths = {
    # cfg
    "${xlib.dirs.user-storage}/ludusavi" = ".config/ludusavi";
    "${xlib.dirs.user-storage}/v2rayN" = ".local/share/v2rayN";
    "/etc/nixos" = "Configuration";

    "${config.home.homeDirectory}/Games/PrismLaunchers/${config.home.username}" =
      ".local/share/PrismLauncher";
    "${xlib.dirs.lamet-drive}/Users/${xlib.device.username}/Music" = "Music";
  };
  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;
in
{
  imports = [
    ./minimal.nix
    ./modules/dconf.nix
    ./modules/packages.nix
    ./modules/plasma-manager.nix
    ./modules/herdr.nix
    # ./modules/noctalia.nix
  ];
  xdg = {
    enable = true;
    autostart.enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.xdg.dataHome}/desktop";
      documents = null;
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Misc/Public";
      templates = null;
      videos = "${config.home.homeDirectory}/Pictures/Videos";
    };
  };
  home = {
    file = mkLinks;
    pointerCursor = {
      enable = true;
      x11.enable = true;
      gtk.enable = true;
      size = 24;
      name = "Qogir";
      package = pkgs.qogir-icon-theme;
    };
    # pkgs.bun нужен для herdr-web-ui plugin (`herdr plugin install devswha/herdr-web-ui`):
    # plugin проверяет PATH и, если bun нет, скачивает generic-linux bun в
    # ~/.local/share/herdr-web-ui/install.<hash>/runtime/bin/bun — а тот динамически
    # слинкован и не запускается на NixOS («NixOS cannot run dynamically linked
    # executables intended for generic linux environments out of the box»).
    # На sapphira bun приходит через импорт ./modules/opencode.nix (см. opencode.nix:271);
    # на rydiwo этот модуль не подключали — добавляем bun сюда, чтобы plugin
    # использовал системный /nix/store/...-bun-*/bin/bun вместо скачивания.
    packages = with pkgs; [ bun ];
  };
  home.activation = {
    yaziSync = ''
      ${pkgs.rsync}/bin/rsync -Lrv "${config.home.homeDirectory}/.config/yazi/" "${xlib.dirs.user-storage}/yazi/"
    '';
  };
}
