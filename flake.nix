{
  description = "oqyude flake";
  inputs = {
    # My
    zeroq-credentials.url = "git+ssh://git@github.com/oqyude/zeroq-credentials.git"; # flake of creds
    zapret.url = "github:oqyude/zapret-easyflake"; # stupid flake of zapret

    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-last-unstable.url = "github:NixOS/nixpkgs/6b4955211758ba47fac850c040a27f23b9b4008f"; # 6027c30c8e9810896b92429f0092f624f7b1aace
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    #nixpkgs-master.url = "github:NixOS/nixpkgs/master"; # e63467437ce61d8d9a36e09254e8d07b472da0c6 # 72353fc1fa61189fb76133d50c519e871c858c39 # 5b38c7435fb1112a8b36b1652286996a7998c5b5
    #nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    #nixpkgs-fingerprint.url = "github:NixOS/nixpkgs/nixos-24.11";
    #nixos.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nix-community
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # extras
    # nix-gaming.url = "github:fufexan/nix-gaming";
    # aagl = {
    #   url = "github:ezKEa/aagl-gtk-on-nix";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     flake-compat.follows = "flake-compat";
    #   };
    # };
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
    # stylix = {
    #   url = "github:danth/stylix";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     home-manager.follows = "home-manager";
    #     flake-compat.follows = "flake-compat";
    #     flake-utils.follows = "flake-utils";
    #   };
    # };
  };
  outputs =
    inputs:
    let
      flakeContext = { inherit inputs; };
      system = "x86_64-linux"; # Замени, если нужно
      pkgs = import inputs.nixpkgs { inherit system; };
      immich-s = import ./pkgs/immich/default.nix { inherit pkgs; };
    in
    {
      nixosConfigurations = {
        atoridu = import ./devices/mini-pc.nix flakeContext; # atoridu
        lamet = import ./devices/mini-laptop.nix flakeContext; # lamet
        otreca = import ./devices/vds.nix flakeContext; # vds
        sapphira = import ./devices/server.nix flakeContext; # sapphira
        wsl = import ./devices/wsl.nix flakeContext; # wsl
      };
      nixosModules = {
        default = import ./modules/default.nix flakeContext;
        desktop = import ./modules/desktop/default.nix flakeContext;
        software = {
          ai = import ./modules/software/ai.nix flakeContext;
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
            aagl = import ./modules/extra/gaming/aagl.nix flakeContext; # https://github.com/ezKEa/aagl-gtk-on-nix
            nix-gaming = import ./modules/extra/gaming/nix-gaming.nix flakeContext; # https://github.com/fufexan/nix-gaming
          };
        };
        server = {
          cloudflared = import ./modules/server/cloudflared.nix flakeContext;
          immich = import ./modules/server/immich.nix flakeContext;
          nextcloud = import ./modules/server/nextcloud.nix flakeContext;
          nginx = import ./modules/server/nginx.nix flakeContext;
          open-webui = import ./modules/server/open-webui.nix flakeContext;
          zerotier = import ./modules/server/zerotier.nix flakeContext;
        };
        vds = {
          cloudflared = import ./modules/vds/cloudflared.nix flakeContext;
          netbird = import ./modules/vds/netbird.nix flakeContext;
          nginx = import ./modules/vds/nginx.nix flakeContext;
          xray = import ./modules/vds/xray.nix flakeContext;
        };
      };
      homeConfigurations = {
        default = import ./home/default.nix flakeContext;
      };
      # homeModules = {
      # };
      packages."x86_64-linux" = {
        immich = immich-s.package;
      };
    };
}
