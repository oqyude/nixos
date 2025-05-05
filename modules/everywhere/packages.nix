{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      nixfmt-tree
      nix-diff
    ];
  };
}
