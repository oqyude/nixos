{
  deviceType = "primary";
  hostname = "atoridu";
  modules = [
    (
      {
        lib,
        pkgs,
        xlib,
        inputs,
        ...
      }:
      {
        imports = with inputs; [
          ./hardware/mini-pc.nix
          ./disko/mini-pc.nix
          ./hardware/logitech.nix
          self.nixosModules.default
        ];

        fileSystems = {
          "${xlib.dirs.therima-drive}" = {
            enable = false;
            device = "/dev/disk/by-uuid/C0A2DDEFA2DDEA44";
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
          "${xlib.dirs.vetymae-drive}" = {
            enable = false;
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
          "${xlib.dirs.soptur-drive}" = {
            enable = false;
            device = "/dev/disk/by-uuid/C00C56E40C56D54E";
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
        };

        boot = {
          kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_stable;
          loader = {
            systemd-boot.enable = lib.mkDefault true;
            efi.canTouchEfiVariables = lib.mkDefault true;
          };
        };

        services.xserver = {
          videoDrivers = [
            "amdgpu"
          ];
        };
        services.pipewire = {
          enable = lib.mkDefault true;
          systemWide = true;
          alsa.enable = false;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          extraConfig.pipewire = {
            "99-default.conf" = {
              "context.properties" = {
                "default.clock.rate" = 96000;
                "default.clock.allowed-rates" = [
                  44100
                  48000
                  96000
                ];
                "default.clock.quantum" = 1024;
                "default.clock.min-quantum" = 256;
                "default.clock.max-quantum" = 2048;
              };
            };
          };
        };
        nixpkgs.config.pulseaudio = true;

        system.stateVersion = "26.05";
      }
    )
  ];
}
