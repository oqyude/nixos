# WIP, Garbage
{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Beets with plugins
  depsOverlay = import ./deps.nix {
    inherit (pkgs) fetchurl fetchgit fetchhg;
    inherit pkgs;
  };
  python3 = pkgs.python3.override {
    packageOverrides = depsOverlay;
  };
  beetsEnv = python3.withPackages (ps: [ ps.beets ]);
in
{

  environment.systemPackages = [
    beetsEnv
    pkgs.imagemagick
  ];

  fileSystems."/mnt/beets/music" = {
    device = "${inputs.zeroq.dirs.music-library}";
    options = [
      "bind"
      "nofail"
    ];
  };

  #   users = {
  #     groups = {
  #       beets = { };
  #     };
  #     users = {
  #       beets = {
  #         isSystemUser = true;
  #         #isNormalUser = true;
  #         description = "beets service";
  #         group = "beets";
  #         homeMode = "0770";
  #         home = "/var/lib/beets";
  #         packages = [ ];
  #         shell = pkgs.bashInteractive;
  #       };
  #     };
  #   };

  systemd.tmpfiles.rules = [
    #     "d /var/lib/beets 0770 beets beets -"
    #     "d /mnt/beets 0770 beets beets -"
    "z /mnt/beets 0755 oqyude users -"
  ];
}
