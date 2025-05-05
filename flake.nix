{
  description = "oqyude flake";

  inputs = {

    zeroq.url = "path:./zeroq"; # my flake of variables
    zapret.url = "github:oqyude/zapret-easyflake"; # my zapret easy-flake

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # 507b63021ada5fee621b6ca371c4fca9ca46f52c
    nixpkgs-last-unstable.url = "github:NixOS/nixpkgs/507b63021ada5fee621b6ca371c4fca9ca46f52c"; # f6db44a8daa59c40ae41ba6e5823ec77fe0d2124
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils.url = "github:numtide/flake-utils"; # wip
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";

    home-manager = {
      url = "github:nix-community/home-manager"; # flake:home-manager
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # other
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
      nixosConfigurations = {
        ${inputs.zeroq.devices.laptop.hostname} = import ./machines/laptop.nix flakeContext; # atoridu config
        ${inputs.zeroq.devices.mini-laptop.hostname} = import ./machines/mini-laptop.nix flakeContext; # lamet config
        ${inputs.zeroq.devices.server.hostname} = import ./machines/server.nix flakeContext; # sapphira config
        ${inputs.zeroq.devices.wsl.hostname} = import ./machines/wsl.nix flakeContext; # wsl config
      };
      nixosModules = {
        default = import ./modules/default.nix flakeContext;
        software = {
          daw = import ./modules/software/daw.nix flakeContext;
          virtualisation = import ./modules/software/virtualisation.nix flakeContext;
          wine = import ./modules/software/wine.nix flakeContext;
        };
        desktop = {
          default = import ./modules/desktop/default.nix flakeContext;
        };
        base = {
          fingerprint = import ./modules/base/fingerprint.nix flakeContext;
          logitech = import ./modules/base/logitech.nix flakeContext;
          zapret = import ./modules/base/zapret.nix flakeContext;
        };
        extra = {
          musnix = import ./modules/extra/musnix.nix flakeContext; # https://github.com/musnix/musnix
          nix-gaming = {
            default = import ./modules/extra/nix-gaming/default.nix flakeContext; # https://github.com/fufexan/nix-gaming
            aagl = import ./modules/extra/nix-gaming/aagl.nix flakeContext; # https://github.com/ezKEa/aagl-gtk-on-nix
          };
        };
      };

      homeConfigurations = {
        main = import ./home/users/main.nix flakeContext;
        server = import ./home/users/server.nix flakeContext;
      };
      homeModules = {
        default = import ./home/default.nix flakeContext;
        packages = import ./home/packages.nix flakeContext;
      };
    };
}
