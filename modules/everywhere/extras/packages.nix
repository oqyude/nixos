{
  config,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      # Common
      nixfmt-tree
      nix-diff

      # Utility
      wget
      curl
      mc
      unzip
      rar
    ];
  };
}
