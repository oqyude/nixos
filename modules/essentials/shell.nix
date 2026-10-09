{
  config,
  pkgs,
  xlib,
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
      beet-p() {
        local base="${xlib.dirs.user-home}/.config/beets/My"
        local rel
        rel=$(realpath --relative-to="$base" "$PWD")
        beet mod "path:$rel" playlist="$*"
      }
      beet-ims() {
        beet im ./ -S $*
      }
      beet-path() {
        realpath --relative-to="${xlib.dirs.user-home}/.config/beets/My" "$1"
      }
    '';
    shellAliases = {
      # shell
      ff = "clear && fastfetch";
      l = "ls -l";
      lg = "lazygit";
      lc = "lazycli";
      st = "systemctl-tui";
      gp = "git pull";
      ns = "nh os switch";
      gp-ns = "gp && ns";
      gc = "git add . && git commit -m 'dev: автокоммит $(date +'%Y-%m-%d %H:%M:%S')'";
      y = "yazi";
      nix-shellp = "nix-shell --run $SHELL -p";
      beet-path-library = "realpath --relative-to='${xlib.dirs.user-home}/.config/beets/My' .";
      z-proxy = "export ALL_PROXY=socks5://localhost:10808";
      zh-proxy = "export HTTPS_PROXY=http://localhost:10808 && export HTTP_PROXY=http://localhost:10808";

      # beets
      beet-ima = "beet im ./ -A";

      # ssh
      z-s = "ssh sapphira";
      z-st = "ssh sapphira-tailscale";
      z-o = "ssh otreca";
      z-ot = "ssh otreca-tailscale";
      z-l = "ssh lamet";
      z-lt = "ssh lamet-tailscale";
      z-p-1 = "ssh pubray-1";
      z-map-local-proxy = "ssh -R 10808:localhost:10808";

      # authelia — Argon2id hash with the exact params configured for the
      # authelia daemon (memory=65536, iterations=3, parallelism=4,
      # salt-length=16). Defaults already match, but explicit so an upstream
      # default change can't silently produce a hash the daemon rejects.
      #
      # Note: the old `authelia hash-password --argon2id` form is from
      # Authelia ≤4.35. Current CLI is `crypto hash generate argon2
      # -v argon2id`. The subcommand takes no positional password — it
      # prompts with confirmation (omit confirmation with `--no-confirm`)
      # or accepts `--password <value>`.
      #
      # Example usage:
      #   authelia-hash
      #     # interactive prompt (twice — confirmation), then hash on stdout
      #   authelia-hash --no-confirm
      #     # single prompt, hash on stdout
      #   authelia-hash --no-confirm --password 'mypassword'
      #     # non-interactive (for scripts)
      #
      # Output goes to stdout — append it to users_database.yml by hand:
      #   authelia-hash --no-confirm >> /mnt/services/authelia/users_database.yml
      authelia-hash = "authelia crypto hash generate argon2 -v argon2id -i 3 -m 65536 -p 4 -s 16";

      # Somethings
      reboot-bios = "sudo systemctl reboot --firmware-setup";

      # Extras
      plasma-manager = "nix run github:nix-community/plasma-manager";
      pip2nix = "nix run github:nix-community/pip2nix --"; # https://github.com/nix-community/pip2nix
      pip2nix-g = "nix run github:nix-community/pip2nix -- generate -r";
      json2nix = "nix run github:sempruijs/json2nix";
    };
  };
  environment.sessionVariables = {
    TUCKR_HOME = "$HOME/Storage/dotfiles";
  };
}
