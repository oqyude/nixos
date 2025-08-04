{
  config,
  ...
}:
{
  imports = [
    ./options.nix
    ./packages.nix
    ./services.nix
    ./settings.nix
    ./tty.nix
  ];
}
