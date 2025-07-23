{
  config,
  pkgs,
  ...
}:
{
  system.userActivationScripts.zshrc = "touch .zshrc";
  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    syntaxHighlighting.enable = true;
    zsh-autoenv.enable = true;
    histSize = 10000;
    loginShellInit = "cd /etc/nixos && clear && fastfetch";
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
    };
    shellAliases = {
      # shell
      ff = "clear && fastfetch";
      l = "ls -l";

      # ssh
      s-1 = "ssh sapphira-1";
      s-1t = "ssh sapphira-1t";
      o-1 = "ssh otreca-1";
      o-1t = "ssh otreca-1t";

      # Somethings
      reboot-bios = "sudo systemctl reboot --firmware-setup";

      # Extras
      plasma-manager = "nix run github:nix-community/plasma-manager";
      pip2nix = "nix run github:nix-community/pip2nix -- generate -r"; # https://github.com/nix-community/pip2nix
    };
  };
}
