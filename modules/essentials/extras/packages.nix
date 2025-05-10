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
      wget
      curl
      mc
      unzip
      rar
    ];
  };
}
