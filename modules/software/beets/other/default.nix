{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  depsOverlay = import ./dependencies.nix { # ./dependencies-full.nix if broken
    inherit (pkgs) fetchurl fetchgit fetchhg;
    inherit pkgs;
  };
  python3 = pkgs.python3.override {
    packageOverrides = depsOverlay;
  };
  beetsEnv = python3.withPackages (ps: with pkgs.python313Packages; [
    #pkgs.beets           # Из nixpkgs (проверь версию!) или оверлея
    beautifulsoup4     # Из nixpkgs
    certifi            # Из nixpkgs
    requests           # Из nixpkgs
    pyyaml             # Из nixpkgs
    unidecode          # Из nixpkgs
    pylast             # Из nixpkgs
    jellyfish          # Из nixpkgs, если есть, или оверлея
    confuse
    #httpcore
    httpx
    packaging
    pycountry
    typing-extensions
    anyio
    ps.python3-discogs-client
    ps.beetcamp        # Из оверлея
  ]);
in
{
  systemd.tmpfiles.rules = [
    "z /mnt/beets 0700 ${config.xlib.device.username} users -" # beets absolute paths
  ];

  users = {
    users = {
      "${config.xlib.device.username}" = {
        packages = [
          beetsEnv
          pkgs.beets
          pkgs.mp3gain
          pkgs.imagemagick
          #pkgs.ffmpeg
        ];
      };
    };
  };
}
