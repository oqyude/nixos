# self: super: {
#   pkgs-src = {
#     immich = super.callPackage ./package.nix { };
#   };
# }

{ pkgs }:
let
  sources = pkgs.lib.importJSON ./sources.json;
in {
  package = pkgs.callPackage ./package.nix {
    # src = pkgs.fetchFromGitHub {
    #   owner = "immich-app";
    #   repo = "immich";
    #   rev = "v${sources.version}";
    #   hash = sources.hash;
    # };
  };
}