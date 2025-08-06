self: super: {
  pkgs-src = {
    immich = super.callPackage ./package.nix { };
  };
}
