{
  config,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      # Minimal
      btop
      broot
      bottom
      fastfetchMinimal

      # yazi
      yaziPlugins.gitui

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
      ncdu
      dust

      # Net Diagnostic
      mtr
      dnsutils

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
    ];
  };
  programs = {
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
    yazi = {
      enable = true;
    };
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
