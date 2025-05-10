{
  description = "oqyude flake";

  inputs = {

    # My
    zeroq.url = "path:./modules/zeroq"; # flake of variables
    zapret.url = "github:oqyude/zapret-easyflake"; # stupid flake of zapret

    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # b6aef6c3553f849e1e6c08f1bcd3061df2b69fc4
    nixpkgs-last-unstable.url = "github:NixOS/nixpkgs/b6aef6c3553f849e1e6c08f1bcd3061df2b69fc4"; # 507b63021ada5fee621b6ca371c4fca9ca46f52c
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    # nix-community
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager"; # flake:home-manager
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      # https://github.com/nix-community/plasma-manager
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # extras
    nix-gaming.url = "github:fufexan/nix-gaming";
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
    grub2-themes = {
      url = "github:vinceliuice/grub2-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nypkgs = {
      # https://github.com/yunfachi/nypkgs
      url = "github:yunfachi/nypkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #     stylix = {
    #       url = "github:danth/stylix";
    #       inputs = {
    #         nixpkgs.follows = "nixpkgs";
    #         home-manager.follows = "home-manager";
    #         flake-compat.follows = "flake-compat";
    #         flake-utils.follows = "flake-utils";
    #       };
    #     };

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
        essentials = {
          default = import ./modules/essentials/default.nix flakeContext;
          terminal = import ./modules/essentials/terminal.nix flakeContext;
        };
        common = {
          fingerprint = import ./modules/common/fingerprint.nix flakeContext;
          logitech = import ./modules/common/logitech.nix flakeContext;
          zapret = import ./modules/common/zapret.nix flakeContext;
        };
        desktop = import ./modules/desktop/default.nix flakeContext;
        software = {
          daw = import ./modules/software/daw.nix flakeContext;
          virtualisation = import ./modules/software/virtualisation.nix flakeContext;
          wine = import ./modules/software/wine.nix flakeContext;
        };
        extra = {
          musnix = import ./modules/extra/musnix.nix flakeContext; # https://github.com/musnix/musnix
          gaming = {
            nix-gaming = import ./modules/extra/gaming/nix-gaming.nix flakeContext; # https://github.com/fufexan/nix-gaming
            aagl = import ./modules/extra/gaming/aagl.nix flakeContext; # https://github.com/ezKEa/aagl-gtk-on-nix
          };
        };
      };

      homeConfigurations = {
        root = import ./modules/home/root.nix flakeContext;
        main = import ./modules/home/main.nix flakeContext;
        server = import ./modules/home/server.nix flakeContext;
      };
      homeModules = {
        default = import ./modules/home/modules/default.nix flakeContext;
        packages = import ./modules/home/modules/packages.nix flakeContext;
        dconf = import ./modules/home/modules/dconf.nix flakeContext;
        plasma-manager = import ./modules/home/modules/plasma-manager.nix flakeContext;
      };
    };
}
