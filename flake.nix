{
  description = "zeroq flake";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/f6db44a8daa59c40ae41ba6e5823ec77fe0d2124";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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
      flakeContext = { inherit inputs zeroq; };
    in

    {
      homeConfigurations = {
        ${zeroq.devices.admin} = import ./home/${zeroq.devices.admin}.nix flakeContext;
        ${zeroq.devices.server.username} = import ./home/${zeroq.devices.server.username}.nix flakeContext;
        extraSpecialArgs = {
          inherit (flakeContext) inputs;
        };
      };
      #homeModules = {
      #  default = import ./homeModules/default.nix flakeContext;
      #};

      nixosConfigurations = {
        ${zeroq.devices.laptop.hostname} =
          import ./machines/${zeroq.devices.laptop.hostname}.nix flakeContext;
        ${zeroq.devices.server.hostname} =
          import ./machines/${zeroq.devices.server.hostname}.nix flakeContext;
        ${zeroq.devices.wsl.hostname} = import ./machines/${zeroq.devices.wsl.hostname}.nix flakeContext;
      };
      nixosModules = {
        aagl = import ./modules/programs/aagl.nix flakeContext;
        default = import ./modules/default.nix flakeContext;
      };

    };
}
