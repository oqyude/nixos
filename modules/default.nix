{ inputs, zeroq, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.config.allowUnfree = true;

  users = {
    defaultUserShell = pkgs.zsh;
  };

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      syntaxHighlighting.enable = true;
      zsh-autoenv.enable = true;
      histSize = 10000;
      #loginShellInit = "cd /etc/nixos && clear && fastfetch";
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
      };
      shellAliases = {
        # shell
        ff = "clear && fastfetch";
        l = "ls -l";

        # nixos
        nir-switch = "sudo nixos-rebuild switch --flake ${zeroq.nixos}#${config.networking.hostName}";
        nir-boot = "sudo nixos-rebuild boot --flake ${zeroq.nixos}#${config.networking.hostName}";
        nir-test = "sudo nixos-rebuild test --flake ${zeroq.nixos}#${config.networking.hostName}";

        # ssh
        s-1 = "ssh sapphira-1";
        s-1t = "ssh sapphira-1t";

        # Somethings
        reboot-bios = "sudo systemctl reboot --firmware-setup";
      };
    };
  };
}
