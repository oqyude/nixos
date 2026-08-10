{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  imports = [
    ./environment
    ./theming.nix
  ];

  # Things every desktop host has in common
  hardware.bluetooth.enable = true;

  i18n.extraLocaleSettings = {
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

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
  };

  security.rtkit.enable = true;

  services = {
    syncthing = {
      enable = true;
      systemService = true;
      configDir = "${xlib.dirs.user-storage}/Syncthing/${config.system.name}";
      dataDir = "${xlib.dirs.user-home}";
      group = "users";
      user = "${xlib.device.username}";
    };
    thermald.enable = true;
    xserver = {
      enable = true;
      xkb = {
        layout = "us,ru";
        variant = "";
        # options = "grp:alt_shift_toggle";
      };
    };
    libinput.enable = true;
    colord.enable = true;
    printing = {
      enable = true;
      cups-pdf.enable = true;
    };
  };

  boot = {
    plymouth = {
      enable = true;
      theme = "bgrt";
    };
    consoleLogLevel = 3; # Enable "Silent boot"
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    loader = {
      timeout = 2;
      efi.canTouchEfiVariables = lib.mkForce false;
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        device = "nodev";
        efiInstallAsRemovable = true;
        efiSupport = true;
        useOSProber = true;
      };
      grub2-theme = {
        enable = true;
        theme = "whitesur";
        icon = "whitesur";
        footer = true;
        customResolution = "1920x1080"; # Optional: Set a custom resolution
      };
    };
  };

  hardware.graphics.enable = true;
  programs = {
    dconf.enable = true;
    gamemode.enable = true;
    steam.enable = true;
    xwayland.enable = true;
  };
  # environment = {
  #   systemPackages = [
  #     pkgs.pcbu-desktop
  #   ];
  #   # sessionVariables = {
  #   #   NIXOS_OZONE_WL = "1";
  #   # };
  # };
}
