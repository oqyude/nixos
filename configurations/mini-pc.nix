# Host: "atoridu" (device: primary)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
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

  # mkNtfsMount returns a `{ "<path>" = { ... }; }` attrset (the shape
  # fileSystems itself wants), so several mounts are combined with
  # mergeAttrsList — not listToAttrs, which would demand `name`/`value`.
  #
  # These three ntfs3 drives are intentionally left unmounted. The entries
  # are kept commented out rather than deleted, so restoring a drive is a
  # matter of uncommenting its block. `enable = false` would declare a drive
  # without mounting it; dropping the field mounts it.
  fileSystems = lib.mergeAttrsList (
    map (xlib.helpers.mkNtfsMount) [
      # {
      #   path = xlib.dirs.therima-drive;
      #   uuid = "C0A2DDEFA2DDEA44";
      # }
      # {
      #   path = xlib.dirs.vetymae-drive;
      #   uuid = "6408433908430A0E";
      # }
      # {
      #   path = xlib.dirs.soptur-drive;
      #   uuid = "C00C56E40C56D54E";
      # }
    ]
  );

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
