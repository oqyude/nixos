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
    {
      enable = true;
      options = "bind,x-systemd.automount,nofail";
      requires = [ "local-fs.target" ];
      type = "none";
      wantedBy = [ "multi-user.target" ];
      what = "/home/${xlib.device.username}/Music";
      where = "/home/${xlib.device.username}/.config/beets";
    }
  ];
}
