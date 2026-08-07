{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
# Shared "strict" home-manager module.
# Works in BOTH contexts:
#   - NixOS hosts (via home-manager.sharedModules or homeConfigurations)
#   - nix-on-droid (via home-manager.config in droid/epral.nix)
# Only home-manager options are used here — no systemd.*, no services.*,
# no users.*, no environment.systemPackages. All paths are parameterized
# through config.home.homeDirectory so /home/oqyude (NixOS) and
# /data/data/com.termux.nix/files/home (termux) both work.
#
# NOTE: intentionally duplicates parts of modules/essentials/{shell,packages}.nix
# (which stay NixOS-only for now). When this module is wired into NixOS hosts
# via sharedModules, deduplicate those files.
{
  home = {
    packages = with pkgs; [
      # Lazy (alias lc)
      lazycli

      # IDE
      fresh-editor # EDITOR

      # Base utils
      curl
      wget
      fd
      tree
      dust
      gdu
      mc
      rsync
      jq
      unzip
      zip
      zstd

      # Net diagnostic
      mtr
      dnsutils

      # Monitoring
      htop
    ];
    sessionVariables = {
      TUCKR_HOME = "$HOME/Storage/dotfiles";
      EDITOR = "fresh";
    };
    file = {
      ".nanorc".text = ''
        set nowrap
        set tabstospaces
        set tabsize 2
      '';
      # Authorized keys for sshd (see modules/termux/default.nix).
      # Declarative for now — the Store/.ssh symlink scheme is postponed.
      ".ssh/authorized_keys".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKduJia+unaQQdN6X5syaHvnpIutO+yZwvfiCP4qKQ/P
      '';
      # nix-on-droid's session-init adds ~/.nix-defexpr/channels to NIX_PATH
      # unconditionally; nix warns about the missing dir on every invocation.
      # Making it exist silences the warning.
      ".nix-defexpr/channels/nixpkgs/.keep".text = "";
    };
  };
  programs = {
    # ---- Shell: zsh ----
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      history.size = 10000;
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
      };
      loginExtra = "clear && fastfetch && cd ~/.config/nix-on-droid";
      # .zshenv — sourced by zsh in ALL sessions incl. non-login ssh commands.
      # runit from nixpkgs defaults to /var/service as SVDIR, but our tree
      # lives at ~/service (symlinked as /etc/service). Export it so that
      # `sv status sshd` works without qualifying the path.
      envExtra = "export SVDIR=/etc/service";
      initContent = ''
        beet-p() {
          local base="${config.home.homeDirectory}/.config/beets/My"
          local rel
          rel=$(realpath --relative-to="$base" "$PWD")
          beet mod "path:$rel" playlist="$*"
        }
        beet-ims() {
          beet im ./ -S $*
        }
        beet-path() {
          realpath --relative-to="${config.home.homeDirectory}/.config/beets/My" "$1"
        }
      '';
      shellAliases = {
        # shell
        ff = "clear && fastfetch";
        l = "ls -l";
        lg = "lazygit";
        lc = "lazycli";
        gp = "git pull";
        ns = "nix-on-droid switch --flake ~/.config/nix-on-droid#${xlib.device.hostname}";
        gp-ns = "gp && ns";
        gc = "git add . && git commit -m 'dev: автокоммит $(date +'%Y-%m-%d %H:%M:%S')'";
        y = "yazi";
        nix-shellp = "nix-shell --run $SHELL -p";
        beet-path-library = "realpath --relative-to='${config.home.homeDirectory}/.config/beets/My' .";
        z-proxy = "export ALL_PROXY=socks5://localhost:10808";
        zh-proxy = "export HTTPS_PROXY=http://localhost:10808 && export HTTP_PROXY=http://localhost:10808";
        nix-dir = "cd ~/.config/nix-on-droid";
        q-ssh = "sv-start"; # start all supervised services (sshd, ...); manage with `sv status sshd` etc

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

        # Extras
        plasma-manager = "nix run github:nix-community/plasma-manager";
        pip2nix = "nix run github:nix-community/pip2nix --"; # https://github.com/nix-community/pip2nix
        pip2nix-g = "nix run github:nix-community/pip2nix -- generate -r";
        json2nix = "nix run github:sempruijs/json2nix";
      };
    };

    # ---- Editor ----
    # NOTE: programs.nano is a NixOS-only module (does not exist in
    # home-manager); write ~/.nanorc directly instead.
    # ---- TUI tools ----
    bat.enable = true;
    lazygit.enable = true;
    fzf.enable = true;

    btop.enable = true;
    broot.enable = true;
    bottom.enable = true;
    fastfetch.enable = true;

    yazi = {
      enable = true;
      # explicit: shared module must behave identically on NixOS (26.05, "y")
      # and nix-on-droid (24.05, legacy "yy")
      shellWrapperName = "y";
      plugins = {
        inherit (pkgs.yaziPlugins)
          gitui
          git
          sudo
          ouch
          rsync
          diff
          mount
          chmod
          dupes
          lazygit
          toggle-pane
          rich-preview
          smart-filter
          full-border
          recycle-bin
          ;
      };
      flavors = {
        nord = pkgs.yaziPlugins.nord;
      };
      theme = {
        flavor = {
          light = "nord";
          dark = "nord";
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [
              "M"
            ];
            run = "plugin mount";
            desc = "Mount manager";
          }
          {
            on = [
              "g"
              "i"
            ];
            run = "plugin lazygit";
            desc = "run lazygit";
          }
          {
            run = "plugin ouch --args=zip";
            on = [
              "g"
              "C"
            ];
            desc = "Compress with ouch";
          }
        ];
      };
      settings = {
        mgr.ratio = [
          1
          1
          4
        ];
      };
    };

    # ---- VCS ----
    git = {
      enable = true;
      settings = {
        user = {
          name = "oqyude";
          email = "oqyude@gmail.com";
        };
        pull = {
          rebase = true;
        };
      };
    };
  };
}
