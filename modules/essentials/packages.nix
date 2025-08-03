{
  config,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      # Encrypt
      age
      sops
      ssh-to-age

      # Nix
      nix-diff
      nix-tree
      nixfmt-tree
      nvd

      # Lazy
      lazycli
      lazydocker
      lazyjournal
      lazysql

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

      # Monitoring
      smartmontools
      btop
      fastfetch

      # Disk
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
