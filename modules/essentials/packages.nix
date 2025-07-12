{
  config,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      # Nix
      nixfmt-tree
      nix-diff
      nix-tree

      # Lazy
      lazycli
      lazydocker
      lazyjournal
      lazysql

      # Base
      curl
      efibootmgr
      fd
      fdupes
      fzf
      gdu
      lsof
      mc
      pciutils
      rsync
      usbutils
      wget

      # Monitoring
      smartmontools
      btop
      fastfetch

      # Disk
      gparted
      parted
      ntfs3g
      exfatprogs # for gparted exfat support

      # Archivers
      rar
      unzip
      zstd
      zip
      xarchiver

      # Net
      ipset
      iptables
      nftables
    ];
  };
}
