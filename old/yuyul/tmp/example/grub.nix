{
  config,
  pkgs,
  lib,
  ...
}:

# WHENEVER THIS FILE CHANGES, ADD THIS FLAG TO YOUR REBUILD COMMAND: --install-bootloader

{
  ## BIOS OPTIONS (ONLY GRUB)
  #boot.loader.grub.enable = true;
  #boot.loader.grub.device = "/dev/vda"; ## DEVICE NAME (DON"T USE LABEL/UUID)
  #boot.loader.grub.useOSProber = true;

  ## UEFI OPTIONS (GRUB OR SYSTEMD_BOOT)
  ##### SYSTEMD_BOOT
  #boot.loader = {
  #systemd-boot.enable = false;
  #efi.canTouchEfiVariables = true;
  #};

  ##### GRUB
  boot = {
    tmp.cleanOnBoot = true;
    plymouth.enable = false; # BECAUsE IT'S NOT NEEDED & (I LOVE DETAILS)

    #kernelParams = [
    #  "resume=LABEL=/dev/disk/by-label/NIXSWAP"
    #  "mem_sleep_default=disk" # If you want sleep to act like hibernate change "deep" to "disk" | reference: https://www.kernel.org/doc/Documentation/power/states.txt
    #];

    # THIS IS FOR VIRTUAL CAM SUPPORT - V4L2LOOPBACK SETUP
    # kernelModules = [ "v4l2loopback" ];
    # extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

    kernel = {
      sysctl = {
        "vm.swappiness" = 20;
      };
    };

    supportedFilesystems = [
      "btrfs"
      "ext4"
      "ntfs"
      "vfat"
      "xfs"
      #"zfs" # DEPENDANT ON OTHER COMPONENT TO BE ENABLED HERE, DON'T BOTHER IF YOU'RE NOT USING THIS FS
      # NETWORK FILESYSTEMS (NOT NEEDED FOR ANY USECASE CURRENTLY)
      #"nfs"
      #"cifs"
    ];

    loader = {

      timeout = 1;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;

        # OPTIONS
        ## GENERAL OPTIONS
        useOSProber = false; # ONLY USE WHEN DUALBOOTING
        enableCryptodisk = false;
        configurationLimit = 100; # (DEFAULT: 100)

        ## APPEARANCE OPTIONS
        font = "${pkgs.hack-font}/share/fonts/truetype/Hack-Regular.ttf";
        fontSize = 26;
        gfxmodeEfi = "auto";
        gfxmodeBios = "auto";

        ## Extra Entries
        memtest86.enable = false; # REPLACED BY THE LIVE ISO

        theme = pkgs.stdenv.mkDerivation {
          pname = "distro-grub-themes";
          version = "3.2";
          src = pkgs.fetchFromGitHub {
            owner = "AdisonCavani";
            repo = "distro-grub-themes";
            rev = "v3.2";
            #hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs="; #v3.1
            hash = "sha256-U5QfwXn4WyCXvv6A/CYv9IkR/uDx4xfdSgbXDl5bp9M=";
          };
          installPhase = "mkdir -vp $out && tar -xf themes/nixos.tar -C $out/";
        };

        extraEntries = ''
          submenu "Power Options" {
            menuentry "Reboot" {
              reboot
            }

            menuentry "Poweroff" {
              halt
            }

            menuentry "UEFI Firmware Settings" {
              fwsetup
            }
          }
        '';
      };
    };
  };
}
