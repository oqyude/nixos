{
  config,
  lib,
  pkgs,
  ...
}:
let
  depsOverlay = import ./dependencies.nix {
    # ./dependencies-full.nix if broken
    inherit (pkgs) fetchurl fetchgit fetchhg;
    inherit pkgs;
  };
  python3 = pkgs.python3.override {
    packageOverrides = depsOverlay;
  };
  beetsEnv = python3.withPackages (ps: [
    ps.beets
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
          pkgs.mp3gain
          pkgs.imagemagick
          #pkgs.ffmpeg
        ];
      };
    };
  };
}
