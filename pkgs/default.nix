{ inputs, ... }@flakeContext:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
in
{
  packages.${system} = {
    rovr = pkgs.callPackage ./rovr { };
    pcbu-desktop = pkgs.callPackage ./pcbu-desktop { };
    # immich = pkgs.callPackage ./immich { };
  };
}
