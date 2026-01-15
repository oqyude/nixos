{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./environment
    ./theming.nix
  ];

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
        copyKernels = false;
      };
      generationsDir.copyKernels = false;
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
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us,ru";
        variant = "";
        options = "grp:alt_shift_toggle";
      };
    };
    libinput.enable = true;
    colord.enable = true;
    printing = {
      enable = true;
      cups-pdf.enable = true;
    };
  };
  # environment.sessionVariables = {
  #   NIXOS_OZONE_WL = "1";
  # };
}
