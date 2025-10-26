{
  config,
  lib,
  pkgs,
  ...
}:
let
  master = import inputs.nixpkgs-master {
    system = "x86_64-linux";
  };
in
{
  services.postgresql.package = pkgs.postgresql_17;
}
