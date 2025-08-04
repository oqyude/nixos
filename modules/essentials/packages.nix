{
  config,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
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

      # Lazy
      lazycli
      lazysql
      lazyjournal

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
    command-not-found.enable = false;
    nix-index.enable = true;
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
