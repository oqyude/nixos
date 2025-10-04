{
  config,
  ...
}:
{
  imports = [
    ./packages.nix
    ./services.nix
    ./settings.nix
    ./systemd-routine.nix
    ./tty.nix
  ];
}
