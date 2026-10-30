{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  beetsEnv = pkgs.python314.withPackages (
    ps: with ps; [
      anyio
      beautifulsoup4
      beetcamp
      beets
      certifi
      charset-normalizer
      colorama
      confuse
      discogs-client
      filetype
      h11
      httpcore
      httpx
      httpx-socks
      idna
      jellyfish
      langdetect
      lap
      llvmlite
      mediafile
      mutagen
      numba
      numpy
      oauthlib
      packaging
      pillow
      platformdirs
      pycountry
      pylast
      pyrate-limiter
      pysocks
      python-dateutil
      pyyaml
      requests
      requests-ratelimiter
      scipy
      six
      socksio
      soupsieve
      typing-extensions
      unidecode
      urllib3
    ]
  );
in
{
  users = {
    users = {
      "${xlib.device.username}" = {
        packages = [
          beetsEnv
          pkgs.mp3gain
          pkgs.imagemagick
          #ffmpeg
        ];
      };
    };
  };
  systemd.mounts = [
    (
      (xlib.helpers.mkSystemdBind {
        what = "/home/${xlib.device.username}/Music";
        where = "/home/${xlib.device.username}/.config/beets";
      })
      // {
        # `what` — симлинк, который создаёт home-manager при СВОЕЙ активации
        # (`~/Music -> /nix/store/…-home-manager-files/Music -> External/Music`).
        # Без этой строки монтирование идёт параллельно с активацией и проигрывает
        # гонку: 2026-10-30 17:33:17 mount сказал «special device
        # /home/oqyude/Music does not exist», юнит упал в failed. Порядок, а не
        # Requires: на хостах без home-manager для этого пользователя зависимость
        # от несуществующего юнита уронила бы монтирование целиком.
        after = [ "home-manager-${xlib.device.username}.service" ];
      }
    )
  ];
}
