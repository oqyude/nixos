{
  description = "zeroq flake";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/f6db44a8daa59c40ae41ba6e5823ec77fe0d2124";

    nixpkgs-staging.url = "github:NixOS/nixpkgs/master"; #"flake:nixpkgs/nixpkgs-unstable"

    flake-compat.url = "github:edolstra/flake-compat";

    home-manager = {
      url = "flake:home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

  };
  outputs =
    inputs:
    let
      zeroq = import ./modules/vars.nix;
      staging = import inputs.nixpkgs-staging { system = "x86_64-linux"; };

      flakeContext = { inherit inputs zeroq staging; };
    in

    {
      homeConfigurations = {
        "${zeroq.user-name}" = import ./home/${zeroq.user-name}.nix flakeContext;
        "${zeroq.server-name}" = import ./home/${zeroq.server-name}.nix flakeContext;
        extraSpecialArgs = {
          inherit (flakeContext) inputs;
        };
      };
      #homeModules = {
      #  default = import ./homeModules/default.nix flakeContext;
      #};

      nixosConfigurations = {
        atoridu = import ./machines/atoridu.nix flakeContext;
        sapphira = import ./machines/sapphira.nix flakeContext;
        wsl = import ./machines/wsl.nix flakeContext;
      };
      nixosModules = {
        zeroq = import ./modules/vars.nix;
        aagl = import ./modules/programs/aagl.nix flakeContext;
      };

    };
}
