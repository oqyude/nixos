{
  imports = inputs.nypkgs.legacyPackages.${pkgs.system}.lib.umport {
    path = ./.;
    include = [
      ./somed4/somef3.nix
    ];
    exclude = [
      ./somed4
      ./somef4.nix
    ];
  };
}
