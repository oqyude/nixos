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

      # Base
      mc
      yazi
      pciutils
      smartmontools
      efibootmgr
      usbutils

      # Data
      wget
      curl
      rsync
      fdupes

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

      # Monitoring
      btop
      fastfetch
    ];
  };
}
