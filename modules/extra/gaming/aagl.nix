# https://github.com/ezKEa/aagl-gtk-on-nix
{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
{
  imports = [ inputs.aagl.nixosModules.default ];
  nix.settings = inputs.aagl.nixConfig; # Set up Cachix
  programs = {
    anime-game-launcher.enable = true;
    #anime-games-launcher.enable = true;
    #honkers-railway-launcher.enable = true;
    #honkers-launcher.enable = true;
    #wavey-launcher.enable = true;
    #sleepy-launcher.enable = true;
  };
}
