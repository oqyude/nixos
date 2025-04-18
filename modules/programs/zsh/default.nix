let
  zeroq = import ...../vars.nix;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    syntaxHighlighting.enable = true;
    zsh-autoenv.enable = true;
    autosuggestions.enable = true;
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
      nir-switch = "sudo nixos-rebuild switch --flake ${zeroq.nixos}#${current.host}";
      nir-boot = "sudo nixos-rebuild boot --flake ${zeroq.nixos}#${current.host}";
      nir-test = "sudo nixos-rebuild test --flake ${zeroq.nixos}#${current.host}";

      # ssh
      s-1 = "ssh sapphira-1";
      s-1t = "ssh sapphira-1t";

      # Somethings
      reboot-bios = "sudo systemctl reboot --firmware-setup";
    };
  };
}
