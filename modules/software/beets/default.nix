{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Beets with plugins
  depsOverlay = import ./dependencies.nix {
    inherit (pkgs) fetchurl fetchgit fetchhg;
    inherit pkgs;
  };
  python3 = pkgs.python3.override {
    packageOverrides = depsOverlay;
  };
  beetsEnv = python3.withPackages (ps: [
    ps.beets # ps.gst-python ps.pygobject3
  ]);
in
{
  systemd.tmpfiles.rules = [
    "z /mnt/beets 0700 ${config.xlib.devices.admin} users -" # beets absolute paths
  ];

  users = {
    users = {
      "${config.xlib.devices.admin}" = {
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
