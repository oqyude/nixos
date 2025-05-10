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

      # Essentials
      curl
      mc
      pciutils
      rar
      smartmontools
      unzip
      usbutils
      wget

      # Tools
      #ntfs3g
      #gparted

      # Color Prorilers
      #xiccd
      #argyllcms
      #colord

      # Net
      #ipset
      #iptables
      #nftables
    ];
  };
}
