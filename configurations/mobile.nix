{
  inputs,
  ...
}@flakeContext:
let
  # Host: epral (Android device via nix-on-droid, aarch64-linux)
  # Integrates with the base defaultModule (imports.self.nixosModules.default),
  # which is trimmed for the "termux" device type: NixOS-only modules
  # (essentials, users.nix, home-manager, sops-nix, disko, grub2-themes)
  # and nixpkgs.overlays are skipped so it evaluates under nix-on-droid's
  # module system (class = "nixOnDroid").
  nixOnDroidModule =
    {
      lib,
      pkgs,
      xlib,
      ...
    }:
    {
      imports = [
        inputs.self.nixosModules.strict
      ];

      xlib.device = {
        type = "termux";
        hostname = "epral";
      };

      # Login shell. nix-on-droid writes /etc/passwd from user.shell on every
      # activation, so `chsh` is useless here — set it in nix instead.
      # (default is bashInteractive)
      user.shell = "${pkgs.zsh}/bin/zsh";

      # Minimal termux settings (nix-on-droid options only:
      # environment.*, nix.*, time.*, user.*, system.*, android-integration.*)

      # user.userName defaults to "nix-on-droid"; set it to override.
      # user.home is read-only: /data/data/com.termux.nix/files/home

      # Simply install just the packages
      environment.packages = with pkgs; [
        # User-facing stuff that you really really want to have
        vim # or some other editor, e.g. nano or neovim
        nano

        # Some common stuff that people expect to have
        bzip2
        diffutils
        findutils
        git
        gnugrep
        gnupg
        gnused
        gnutar
        gzip
        hostname
        man
        ncurses
        openssh
        procps
        psmisc # provides killall (attr `killall` was removed from nixpkgs)
        treefmt
        tzdata
        unzip
        util-linux # renamed from utillinux
        zip
      ];

      # Backup etc files instead of failing to activate generation if a file already exists in /etc
      environment.etcBackupExtension = ".bak";

      # Shared userspace home-manager config (same cozy shell as on NixOS hosts).
      # nix-on-droid forces home.username / home.homeDirectory from user.*,
      # so the strict module must not set them.
      # xlib is injected via home-manager.extraSpecialArgs (the HM submodule
      # does not inherit the nix-on-droid module args).
      home-manager = {
        useGlobalPkgs = true;
        backupFileExtension = "hm-bak";
        extraSpecialArgs = {
          inherit xlib;
        };
        config = { ... }: {
          imports = [
            ../home/termux.nix
          ];
          home.stateVersion = "24.05";
        };
      };

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
  extraSpecialArgs = {
    deviceType = "termux";
  };
}
