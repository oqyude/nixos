{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  stable = import inputs.nixpkgs-beets {
    system = "x86_64-linux";
  };
in
let
  # depsOverlay = import ./dependencies.nix {
  #   # ./dependencies-full.nix if broken
  #   inherit (pkgs) fetchurl fetchgit fetchhg;
  #   inherit pkgs;
  # };
  # python3 = pkgs.python3.override {
  #   packageOverrides = depsOverlay;
  # };
  beetsEnv = pkgs.python313.withPackages (
    ps: with ps; [
      anyio #
      lap #
      llvmlite #
      scipy #
      requests-ratelimiter #
      pyrate-limiter #
      numpy #
      numba #
      et-xmlfile
      markdown-it-py
      mdurl
      openpyxl
      pygments
      rich
      setuptools #
      pysocks #
      beautifulsoup4
      beetcamp
      beets
      certifi
      charset-normalizer
      colorama
      confuse
      discogs-client
      # exceptiongroup
      filetype
      h11
      httpcore
      httpx
      httpx-socks
      socksio
      idna
      jellyfish
      langdetect
      mediafile
      # munkres
      # musicbrainzngs
      mutagen
      oauthlib
      packaging
      pillow
      platformdirs
      # pycountry
      pylast
      python-dateutil
      pyyaml
      requests
      six
      # sniffio
      soupsieve
      typing-extensions
      unidecode
      urllib3
    ]
  );
in
{
  # nixpkgs.config.allowBroken = true;

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
      where = "/mnt/beets/music";
    }
  ];
  # fileSystems."/mnt/beets/music" = {
  #   device = "/home/${xlib.device.username}/Music"; # "${xlib.dirs.vetymae-drive}/Users/User/Music"
  #   fsType = "none";
  #   options = [
  #     # "bind"
  #     "uid=1000"
  #     "gid=1000"
  #     "fmask=0077"
  #     "dmask=0077"
  #     "nofail"
  #     #"x-systemd.device-timeout=0"
  #   ];
  # };

  systemd.tmpfiles.rules = [
    "z /mnt/beets 0700 ${xlib.device.username} users -" # beets absolute paths
  ];
}
