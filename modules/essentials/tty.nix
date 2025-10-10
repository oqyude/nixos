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
    shellInit = ''
      beetn() {
        echo "$*" | aichat -cer beets
      }
    '';
    shellAliases = {
      # shell
      ff = "clear && fastfetch";
      l = "ls -l";
      lg = "lazygit";
      st = "systemctl-tui";
      gp = "git pull";
      ns = "nh os switch";
      gp-ns = "gp && ns";

      # ssh
      z-s = "ssh sapphira";
      z-st = "ssh sapphira-tailscale";
      z-o = "ssh otreca";
      z-ot = "ssh otreca-tailscale";
      z-p-1 = "ssh pubray-1";

      # Somethings
      reboot-bios = "sudo systemctl reboot --firmware-setup";

      # Extras
      plasma-manager = "nix run github:nix-community/plasma-manager";
      pip2nix = "nix run github:nix-community/pip2nix --"; # https://github.com/nix-community/pip2nix
      pip2nix-g = "nix run github:nix-community/pip2nix -- generate -r";
      json2nix = "nix run github:sempruijs/json2nix";
    };
  };
}
