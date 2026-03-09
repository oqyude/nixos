# https://github.com/fufexan/nix-gaming
{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
{
  nix.settings = {
    substituters = [ "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };
}
