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
      #         default = import ./home/default.nix flakeContext;
      #       };
      hosts/*nixosConfigurations*/ = {
        atoridu = import ./hosts/atoridu.nix flakeContext;
        sapphira = import ./hosts/sapphira.nix flakeContext;
        wsl = import ./hosts/sapphira.nix flakeContext;
      };
    };
}
