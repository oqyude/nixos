{ inputs, ... }@flakeContext:
let
  # Host: epral (Android device via nix-on-droid, aarch64-linux)
  # Adapted from test/nix-on-droid.nix — the config that works on the device.
  # NOTE: nix-on-droid uses its own module system (class = "nixOnDroid").
  # Only nix-on-droid options exist here: environment.*, nix.*, time.*,
  # networking.hosts, user.*, home-manager.*, system.stateVersion, android-integration.*
  # NixOS-only options (boot.*, services.*, hardware.*, fileSystems.*, ...) do NOT exist.
  nixOnDroidModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # user.userName defaults to "nix-on-droid"; set it to override.
      # user.home is read-only: /data/data/com.termux.nix/files/home

      # Simply install just the packages
      environment.packages = with pkgs; [
        # User-facing stuff that you really really want to have
        vim # or some other editor, e.g. nano or neovim
        nano

        # Some common stuff that people expect to have
        openssh
        treefmt
        git
        procps
        psmisc # provides killall (attr `killall` was removed from nixpkgs)
        diffutils
        findutils
        util-linux # renamed from utillinux
        tzdata
        hostname
        man
        gnugrep
        gnupg
        gnused
        gnutar
        bzip2
        gzip
        zip
        unzip
      ];

      # Backup etc files instead of failing to activate generation if a file already exists in /etc
      environment.etcBackupExtension = ".bak";

      # Read the changelog before changing this value
      system.stateVersion = "24.05";

      # Set up nix for flakes
      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';

      # Set your time zone
      time.timeZone = "Europe/Moscow";

      android-integration.termux-setup-storage.enable = true;
    };
in
inputs.nix-on-droid.lib.nixOnDroidConfiguration {
  pkgs = import inputs.nixpkgs {
    system = "aarch64-linux";
  };
  modules = [
    nixOnDroidModule
  ];
}
