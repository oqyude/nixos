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
  ];

  boot = {
    plymouth = {
      enable = true;
      theme = "bgrt";
      extraConfig = ''
        [Daemon]
        ShowDelay=5
      '';
      # themePackages = with pkgs; [
      #   # By default we would install all themes
      #   (adi1090x-plymouth-themes.override {
      #     selected_themes = [ "rings" ];
      #   })
      # ];
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
    loader.timeout = 0;
  };

  programs = {
    xwayland.enable = true;
    dconf.enable = true;
  };
  services = {
    xserver = {
      enable = true;
      videoDrivers = [
        #"amdgpu"
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
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
