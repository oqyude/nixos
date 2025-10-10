{
  config,
  lib,
  pkgs,
  xlib,
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
    "z /mnt/beets 0700 ${xlib.device.username} users -" # beets absolute paths
  ];

  users = {
    users = {
      "${xlib.device.username}" = {
        packages = [
          beetsEnv
          pkgs.mp3gain
          pkgs.imagemagick
          #pkgs.ffmpeg
        ];
      };
    };
  };
  fileSystems."/mnt/beets/music" = {
    device = "/home/${xlib.device.username}/Music"; # "${xlib.dirs.vetymae-drive}/Users/User/Music"
    options = [
      "bind"
      "uid=1000"
      "gid=1000"
      "fmask=0077"
      "dmask=0077"
      "nofail"
      #"x-systemd.device-timeout=0"
    ];
  };
}
