# WIP, Garbage
{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  base-packages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenv
  ];
  # Файл requirements.txt с перечислением плагинов
  requirements = pkgs.writeText "beets-requirements.txt" ''
    beets[bandcamp,deezer,discogs,duplicates,edit,embedart,fetchart,info,lastgenre,lyrics,missing,rewrite,scrub,smartplaylist,spotify]
    beetcamp
    typing_extensions
  '';
in
{

  fileSystems."/mnt/beets/music" = {
    device = "${inputs.zeroq.dirs.music-library}";
    options = [ "bind" ];
  };

  users = {
    groups = {
      beets = {};
    };
    users = {
      beets = {
        isSystemUser = true;
        #isNormalUser = true;
        description = "beets service";
        group = "beets";
        homeMode = "0770";
        home = "/var/lib/beets";
        packages = base-packages;
        shell = pkgs.bashInteractive;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/beets 0770 beets beets -"
    "d /mnt/beets 0770 beets beets -"
  ];

  # Автоматическая установка плагинов при старте системы
  system.activationScripts.beets-venv = ''
    # Создаём virtualenv если не существует
    if [ ! -d "/var/lib/beets/venv" ]; then
      ${pkgs.sudo}/bin/sudo -u beets ${pkgs.python312}/bin/python -m venv /var/lib/beets/venv
    fi

    # Обновляем pip и устанавливаем зависимости
    ${pkgs.sudo}/bin/sudo -u beets /var/lib/beets/venv/bin/pip install --upgrade pip wheel
    ${pkgs.sudo}/bin/sudo -u beets /var/lib/beets/venv/bin/pip install -r ${requirements}
  '';

  # Симлинк для удобного вызова beets из-под основного пользователя
#   environment.systemPackages = [
#     (pkgs.writeScriptBin "beets" ''
#       #!/bin/sh
#       exec sudo -u beets /var/lib/beets/venv/bin/beets "$@"
#     '')
#   ];
}
