{
  config,
  ...
}:
{
  imports = [
    ./packages.nix
    ./services.nix
    ./settings.nix
    ./tty.nix
  ];
}
