{
  config,
  ...
}:
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./services.nix
    ./settings.nix
    ./tty.nix
    ./users.nix
  ];
}
