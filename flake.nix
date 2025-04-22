{
  description = "oqyude flake";

  inputs = {

    zeroq.url = "path:./zeroq"; # my flake of variables

    nixpkgs.url = "github:NixOS/nixpkgs/f6db44a8daa59c40ae41ba6e5823ec77fe0d2124";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils.url = "github:numtide/flake-utils"; # wip

    home-manager = {
      url = "flake:home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # additional
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs =
    inputs:
    let
      flakeContext = { inherit inputs; };
    in

    {
      homeConfigurations = {
        ${inputs.zeroq.devices.admin} = import ./configurations/home/${inputs.zeroq.devices.admin}.nix flakeContext; # main user
        ${inputs.zeroq.devices.server.username} = import ./configurations/home/${inputs.zeroq.devices.server.username}.nix flakeContext; # server user
      };
      homeModules = {
        default = import ./modules/home/default.nix flakeContext; # wip
      };

      nixosConfigurations = {
        ${inputs.zeroq.devices.laptop.hostname} = import ./configurations/machines/${inputs.zeroq.devices.laptop.hostname}.nix flakeContext; # laptop config
        ${inputs.zeroq.devices.server.hostname} = import ./machines/${inputs.zeroq.devices.server.hostname}.nix flakeContext; # server config
        ${inputs.zeroq.devices.wsl.hostname} = import ./configurations/machines/${inputs.zeroq.devices.wsl.hostname}.nix flakeContext; # wsl config
      };
      nixosModules = {
        default = import ./modules/default.nix flakeContext; # global config
        aagl = import ./modules/additional/aagl.nix flakeContext; # an anime game launcher module
      };

    };
}
