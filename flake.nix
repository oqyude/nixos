{
  description = "oqyude flake";
  inputs = {
    # My
    zeroq-credentials.url = "git+ssh://git@github.com/oqyude/zeroq-credentials.git"; # flake of creds
    zapret.url = "github:oqyude/zapret-easyflake"; # stupid flake of zapret

    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-last-unstable.url = "github:NixOS/nixpkgs/6b4955211758ba47fac850c040a27f23b9b4008f";
    # nixpkgs-calibre.url = "github:NixOS/nixpkgs/35f590344ff791e6b1d6d6b8f3523467c9217caf";
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nixpkgs-immich.url = "github:NixOS/nixpkgs/007307973c7183cc2d529b83b1a1e81e14b85ebe";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master"; # e63467437ce61d8d9a36e09254e8d07b472da0c6 # 72353fc1fa61189fb76133d50c519e871c858c39 # 5b38c7435fb1112a8b36b1652286996a7998c5b5
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
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
    
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
  
    flake-compat.url = "github:edolstra/flake-compat";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    # flake-utils.url = "github:numtide/flake-utils";
    # flake-parts.url = "github:hercules-ci/flake-parts";
    # nur = {
    #   url = "github:nix-community/NUR";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
    compose2nix = {
      url = "github:aksiksi/compose2nix";
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
    in
    { 
      deploy.nodes = {
        sapphira = {
          hostname = "sapphira";
          deploy = {
            sshUser = "oqyude";
          };
          profiles.system = {
            # user = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.sapphira;
          };
        };
      };
      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) deploy-rs.lib;
    }
    // (import ./home flakeContext)
    // (import ./configurations flakeContext)
    // (import ./modules flakeContext)
    // (import ./pkgs flakeContext);
}
