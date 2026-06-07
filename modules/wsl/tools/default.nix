{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    gcc
    gdb
    cmake
    gnumake

    nlohmann_json
  ];
}
