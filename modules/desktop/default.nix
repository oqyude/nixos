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

    inputs.grub2-themes.nixosModules.default # grub2 themes module
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
    loader = {
      timeout = 2;
      efi.canTouchEfiVariables = lib.mkForce false;
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        useOSProber = true;
        efiInstallAsRemovable = true;
        efiSupport = true;
        device = "nodev";
        #copyKernels = true;
      };
      grub2-theme = {
        enable = true;
        theme = "whitesur";
        icon = "whitesur";
        footer = true;
        #bootMenuConfig = "";
        customResolution = "1920x1080"; # Optional: Set a custom resolution
      };
    };
  };
  hardware.graphics.enable = true;
  programs = {
    xwayland.enable = true;
    dconf.enable = true;
    adb.enable = true;
    gamemode.enable = true;
    steam.enable = true;
    #gamescope.enable = true;
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
        #accelStepScroll = 0.1;
        #accelProfile = "flat";
      };
      touchpad = {
        #accelProfile = "flat";
      };
    };
    colord.enable = true;
    printing = {
      enable = true;
      cups-pdf.enable = true;
    };
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  #   environment = {
  #     systemPackages = with pkgs; [
  #     ];
  #   };
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
