{ inputs, ... }@flakeContext:
let
  # Host: epral (Android device via nix-on-droid, aarch64-linux)
  # NOTE: nix-on-droid uses its own module system (class = "nixOnDroid").
  # Only options defined by nix-on-droid are available here:
  #   environment.*, nix.*, time.*, networking.hosts, user.*, home-manager.*, system.stateVersion
  # NixOS-only options (boot.*, services.*, hardware.*, fileSystems.*, ...) do NOT exist here.
  nixOnDroidModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # user.home is read-only and always /data/data/com.termux.nix/files/home
      user.userName = "oqyude"; # matches xlib.device.username used by the NixOS hosts

      environment = {
        # Base CLI packages
        packages = with pkgs; [
          vim
          git
          ripgrep
          htop
          file
          tmux
        ];
        # Backup existing files in /etc instead of failing activation
        etcBackupExtension = ".bak";
      };

      # Set up nix for flakes
      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';

      time.timeZone = "Europe/Moscow";

      # Read the changelog before changing this value.
      # nix-on-droid currently supports state versions only up to "24.05".
      system.stateVersion = "24.05";

      # home-manager is built in; point it at this repo's home-manager input
      # and keep the config self-contained (repo home.nix depends on NixOS-only xlib.dirs).
      # home-manager = {
      #   backupFileExtension = "hm-bak";
      #   useGlobalPkgs = true;
      #   config = { config, lib, pkgs, ... }: {
      #     home.stateVersion = "24.05";
      #     home.packages = with pkgs; [ ];
      #   };
      # };
    };
in
inputs.nix-on-droid.lib.nixOnDroidConfiguration {
  pkgs = import inputs.nixpkgs {
    system = "aarch64-linux";
  };
  modules = [
    nixOnDroidModule
  ];
  extraSpecialArgs = {
    inherit inputs;
  };
}
