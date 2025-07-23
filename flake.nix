{
  description = "oqyude flake";

  inputs = {

    # My
    zeroq.url = "path:./modules/zeroq"; # flake of variables
    zeroq-credentials.url = "github:oqyude/zeroq-credentials"; # flake of variables
    zapret.url = "github:oqyude/zapret-easyflake"; # stupid flake of zapret

    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-last-unstable.url = "github:NixOS/nixpkgs/be9e214982e20b8310878ac2baa063a961c1bdf6";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-fingerprint.url = "github:NixOS/nixpkgs/nixos-24.11";

    # nix-community
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
        atoridu = import ./devices/mini-pc.nix flakeContext; # atoridu
        lamet = import ./devices/mini-laptop.nix flakeContext; # lamet
        sapphira = import ./devices/server.nix flakeContext; # sapphira
        otreca = import ./devices/vds.nix flakeContext; # vds
        wsl = import ./devices/wsl.nix flakeContext; # wsl
      };
      nixosModules = {
        default = import ./modules/default.nix flakeContext;
        desktop = import ./modules/desktop/default.nix flakeContext;
        software = {
          beets = import ./modules/software/beets/default.nix flakeContext;
          daw = import ./modules/software/daw.nix flakeContext;
          virtual = import ./modules/software/virtual.nix flakeContext;
          wine = import ./modules/software/wine.nix flakeContext;
        };
        extra = {
          self = {
            fingerprint = import ./modules/extra/self/fingerprint.nix flakeContext;
            zapret = import ./modules/extra/self/zapret.nix flakeContext;
          };
          musnix = import ./modules/extra/musnix.nix flakeContext; # https://github.com/musnix/musnix
          gaming = {
            nix-gaming = import ./modules/extra/gaming/nix-gaming.nix flakeContext; # https://github.com/fufexan/nix-gaming
            aagl = import ./modules/extra/gaming/aagl.nix flakeContext; # https://github.com/ezKEa/aagl-gtk-on-nix
          };
        };
        server = {
          cloudflared = import ./modules/server/cloudflared.nix flakeContext;
          immich = import ./modules/server/immich.nix flakeContext;
          nextcloud = import ./modules/server/nextcloud.nix flakeContext;
          nginx = import ./modules/server/cloudflared.nix flakeContext;
          zerotier = import ./modules/server/zerotier.nix flakeContext;
          xray = import ./modules/server/xray.nix flakeContext;
        };
      };

      homeConfigurations = {
        root = import ./home/root.nix flakeContext;
        main = import ./home/main.nix flakeContext;
        server = import ./home/server.nix flakeContext;
      };
      homeModules = {
        packages = import ./home/modules/packages.nix flakeContext;
        default = import ./home/modules/default.nix flakeContext;
        dconf = import ./home/modules/dconf.nix flakeContext;
        plasma-manager = import ./home/modules/plasma-manager.nix flakeContext;
      };
    };
}
