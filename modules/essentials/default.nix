{
  config,
  ...
}:
{
  imports = [
    ./packages.nix
    ./services.nix
    ./settings.nix
    ./ssh.nix
    ./systemd-routines.nix
    ./shell.nix
  ];
}
