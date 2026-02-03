{
  config,
  pkgs,
  inputs,
  ...
}:
let
  master = import inputs.nixpkgs-master {
    system = "x86_64-linux";
  };
in
{
  environment = {
    systemPackages = with pkgs; [
      # Minimal
      btop
      broot
      bottom
      fastfetchMinimal

      # Encrypt
      age
      sops
      ssh-to-age

      # Nix
      nix-diff
      nix-tree
      nixfmt-tree
      nvd
      nix-du
      nix-prefetch-scripts
      deploy-rs

      # Lazy
      lazycli
      lazysql
      lazyjournal
      systemctl-tui

      # Base
      curl
      # efibootmgr
      fd
      fdupes
      fzf
      gdu
      lsof
      mc
      pciutils
      usbutils
      rsync
      wget
      tree
      dust
      master.flow-control

      # Net Diagnostic
      mtr
      dnsutils
      inetutils

      # Android tools
      android-tools

      # Monitoring
      smartmontools

      # Disk
      parted
      ntfs3g
      exfatprogs # for gparted exfat support

      # Archivers
      rar
      unzip
      zstd
      zip
      #xarchiver

      # Net
      ipset
      iptables
      nftables
      openssl

      # Test
      jocalsend
      lazydocker
      dtop
      tlrc
      lazyssh
      tuios
      mcat
      framework-tool-tui
      fresh-editor
      bluetui
    ];
  };
  environment.variables.EDITOR = "flow";
  programs = {
    # nix-ld.enable = true;
    nano = {
      enable = true;
      nanorc = ''
        set nowrap
        set tabstospaces
        set tabsize 2      
      '';
      syntaxHighlight = true;
    };
    yazi = {
      enable = false;
      plugins = {
        inherit (pkgs.yaziPlugins)
          gitui
          git
          sudo
          ouch
          rsync
          diff
          mount
          chmod
          dupes
          lazygit
          toggle-pane
          rich-preview
          smart-filter
          full-border
          recycle-bin
          ;
      };
      flavors = {
        nord = pkgs.yaziPlugins.nord;
      };
      settings = {
        yazi = {
          mgr.ratio = [
            1
            1
            4
          ];
        };
        keymap = {
          mgr.prepend_keymap = [
            {
              on = [
                "g"
                "i"
              ];
              run = "plugin lazygit";
              desc = "run lazygit";
            }
            {
              run = "plugin ouch --args=zip";
              on = [
                "g"
                "C"
              ];
              desc = "Compress with ouch";
            }
          ];
        };
        theme = {
          flavor = {
            light = "nord";
            dark = "nord";
          };
        };
      };
    };
    git = {
      enable = true;
      config = {
        user = {
          name = "oqyude";
          email = "oqyude@gmail.com";
        };
      };
    };
    lazygit.enable = true;
    bat.enable = true;
    # command-not-found.enable = false;
    # nix-index.enable = true;
    nh = {
      enable = true;
      flake = "/etc/nixos";
      clean = {
        enable = true;
        extraArgs = "--keep 3 --keep-since 2d";
        dates = "daily";
      };
    };
  };
}
