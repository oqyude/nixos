{
  config,
  ...
}:
{
  imports = [
    ./packages.nix
    ./services.nix
    ./settings.nix
    ./systemd-routines.nix
    ./shell.nix
  ];
}
