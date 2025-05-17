# WIP, Garbage
{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{

  nixpkgs.overlays = [
    (self: super: {
      python3 = super.python3.override {
        packageOverrides = import ./python-deps.nix {
          pkgs = self;
          inherit (super) fetchurl fetchgit fetchhg;
        };
      };
    })
  ];

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
        packages = [(pkgs.python3.withPackages (ps: [ ps.beets ps.beetcamp ]))];
        shell = pkgs.bashInteractive;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/beets 0770 beets beets -"
    "d /mnt/beets 0770 beets beets -"
  ];
}
