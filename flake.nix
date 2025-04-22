{
  description = "zeroq flake";

  inputs = {

    zeroq.url = "path:./vars";
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
      #zeroq = import ./modules/vars.nix;
      zeroq = inputs.zeroq;
      flakeContext = {
        inherit inputs zeroq;
      };
    in

    {
      homeConfigurations = {
        ${inputs.zeroq.devices.admin} = import ./configurations/home/${inputs.zeroq.devices.admin}.nix flakeContext;
        ${inputs.zeroq.devices.server.username} = import ./configurations/home/${inputs.zeroq.devices.server.username}.nix flakeContext;
#         extraSpecialArgs = {
#           inherit (flakeContext) inputs;
#         };
      };
      homeModules = {
        default = import ./modules/home/default.nix flakeContext;
      };

      nixosConfigurations = {
        ${inputs.zeroq.devices.laptop.hostname} =
          import ./configurations/machines/${inputs.zeroq.devices.laptop.hostname}.nix flakeContext;
        ${inputs.zeroq.devices.server.hostname} =
          import ./machines/${inputs.zeroq.devices.server.hostname}.nix flakeContext;
        ${inputs.zeroq.devices.wsl.hostname} = import ./configurations/machines/${inputs.zeroq.devices.wsl.hostname}.nix flakeContext;
      };
      nixosModules = {
        default = import ./modules/default.nix flakeContext;
        aagl = import ./modules/additional/aagl.nix flakeContext;
      };

    };
}
