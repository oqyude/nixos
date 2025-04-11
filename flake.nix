{
  description = "zeroq automate";
  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    home-manager.url = "flake:home-manager";
  };
  outputs =
    inputs:
    let
      flakeContext = {
        inherit inputs;
      };
    in
    {
      #       homeModules = {
      #         default = import ./homeModules/default.nix flakeContext;
      #       };
      nixosConfigurations = {
        atoridu = import ./nixosConfigurations/atoridu.nix flakeContext;
        sapphira = import ./nixosConfigurations/sapphira.nix flakeContext;
        #modules = [ ./old.nix ];
      };
    };
}
