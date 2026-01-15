{
  inputs,
  ...
}@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      xlib,
      ...
    }:
    {
      xlib.device = {
        type = "primary";
        hostname = "lamet";
      };

      imports = with inputs; [
        nixos-hardware.nixosModules.chuwi-minibook-x
        ./hardware/mini-laptop.nix
        self.nixosModules.default
      ];

      boot = {
        kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_latest;
        loader = {
          systemd-boot.enable = lib.mkDefault true;
          efi.canTouchEfiVariables = lib.mkDefault true;
        };
      };

      fileSystems."${xlib.dirs.vetymae-drive}" = {
        device = "/dev/disk/by-uuid/6408433908430A0E";
        fsType = "ntfs3";
        options = [
          "defaults"
          "uid=1000"
          "gid=1000"
          "fmask=0007"
          "dmask=0007"
          "nofail"
        ];
      };

      hardware = {
        bluetooth.enable = true;
      };

      networking = {
        hostName = "${xlib.device.hostname}";
        networkmanager.enable = true;
        firewall.enable = false;
      };

      i18n = {
        extraLocaleSettings = {
          LC_ADDRESS = "ru_RU.UTF-8";
          LC_IDENTIFICATION = "ru_RU.UTF-8";
          LC_MEASUREMENT = "ru_RU.UTF-8";
          LC_MONETARY = "ru_RU.UTF-8";
          LC_NAME = "ru_RU.UTF-8";
          LC_NUMERIC = "ru_RU.UTF-8";
          LC_PAPER = "ru_RU.UTF-8";
          LC_TELEPHONE = "ru_RU.UTF-8";
          LC_TIME = "ru_RU.UTF-8";
        };
      };

      services = {
        xserver = {
          videoDrivers = [
            "nomodeset"
          ];
        };
        # syncthing = {
        #   enable = true;
        #   systemService = true;
        #   configDir = "${xlib.dirs.user-storage}/Syncthing/${config.system.name}";
        #   dataDir = "${xlib.dirs.user-home}";
        #   group = "users";
        #   user = "${xlib.device.username}";
        # };
        # pipewire = {
        #   enable = lib.mkDefault true;
        #   systemWide = true;
        #   alsa.enable = false;
        #   alsa.support32Bit = true;
        #   pulse.enable = true;
        #   jack.enable = true;
        #   extraConfig.pipewire = {
        #     "99-default.conf" = {
        #       "context.properties" = {
        #         "default.clock.rate" = 96000;
        #         "default.clock.allowed-rates" = [
        #           44100
        #           48000
        #           96000
        #         ];
        #         "default.clock.quantum" = 1024;
        #         "default.clock.min-quantum" = 256;
        #         "default.clock.max-quantum" = 2048;
        #       };
        #     };
        #   };
        # };
        thermald.enable = true;
        earlyoom.enable = true;
      };
      # security = {
      #   rtkit.enable = true;
      # };

      hardware.intel-gpu-tools.enable = true;

      system.stateVersion = "26.05";
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "primary";
  };
}
