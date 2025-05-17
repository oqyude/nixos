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
  beetsEnv = python3.withPackages (ps: [ ps.beets ]);
in
{
  fileSystems."/mnt/beets/music" = {
    device = "${inputs.zeroq.dirs.music-library}";
    options = [
      "bind"
      "nofail"
    ];
  };

  systemd.tmpfiles.rules = [
    "z /mnt/beets 0700 ${inputs.zeroq.dirs.music-library} users -" # beets absolute paths
  ];

  users = {
    users = {
      "${inputs.zeroq.devices.admin}" = {
        packages = [
          beetsEnv
          pkgs.imagemagick
        ];
      };
    };
  };
}
