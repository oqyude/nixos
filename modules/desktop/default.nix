{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./environment/kde.nix
    #./environment/gnome.nix
    #./environment/budgie.nix

    ./packages.nix
  ];

  boot = {
    plymouth = {
      enable = true;
      theme = "bgrt";
      #extraConfig = ''
      #  ShowDelay=2
      #'';
    };
    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 2;
  };
  hardware.graphics.enable = true;
  programs = {
    xwayland.enable = true;
    dconf.enable = true;
  };
  services = {
    xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
      xkb = {
        layout = "us,ru";
        variant = "";
        options = "grp:alt_shift_toggle";
      };
    };
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
      };
      touchpad = {
        accelProfile = "flat";
      };
    };
    colord.enable = true;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  #   systemd.services.xiccd = { # Color Profiler bus for x11
  #     enable = false;
  #     description = "Xiccd Screen Color Profiler";
  #     serviceConfig = {
  #       ExecStart = "${pkgs.xiccd}/bin/xiccd";
  #       ExecStop = "pkill xiccd";
  #       Restart = "always";
  #     };
  #     wantedBy = [ "dbus.service" ];
  #     after = [ "dbus.service" ];
  #     partOf = [ "dbus.service" ];
  #   };
}
