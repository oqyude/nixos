{
  description = "oqyude flake";
  inputs = {
    # My
    zeroq-credentials.url = "git+ssh://git@github.com/oqyude/zeroq-credentials.git"; # flake of creds
    zeroq-deploy.url = "path:./deploy";
    zapret.url = "github:oqyude/zapret-easyflake"; # stupid flake of zapret

    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nixpkgs-last-unstable.url = "github:NixOS/nixpkgs/6b4955211758ba47fac850c040a27f23b9b4008f";
    # nixpkgs-calibre.url = "github:NixOS/nixpkgs/e6f23dc08d3624daab7094b701aa3954923c6bbb";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    #nixpkgs-fingerprint.url = "github:NixOS/nixpkgs/nixos-24.11";

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
        utils.follows = "utils";
      };
    };

    utils.url = "github:numtide/flake-utils";
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
    # nix-index-database = {
    #   url = "github:nix-community/nix-index-database";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
    }
    // (import ./configurations flakeContext)
    // (import ./deploy flakeContext)
    // (import ./home flakeContext)
    // (import ./modules flakeContext)
    // (import ./overlays flakeContext)
    // (import ./pkgs flakeContext);
}
