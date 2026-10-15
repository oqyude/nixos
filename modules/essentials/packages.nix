{
  config,
  pkgs,
  inputs,
  xlib,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      # Minimal
      btop
      broot
      bottom
      fastfetch

      # Encrypt
      age
      sops
      ssh-to-age

      # Nix
      nix-diff
      nix-tree
      nixfmt-tree
      nvd
      nix-du
      nix-prefetch-scripts
      deploy-rs

      # Lazy
      lazycli
      lazysql
      lazyjournal
      systemctl-tui

      # IDE
      yaml-language-server
      nil
      fresh-editor
      #flow-control

      # Base
      curl
      # efibootmgr
      fd
      fdupes
      fzf
      gdu
      lsof
      mc
      pciutils
      usbutils
      rsync
      wget
      tree
      dust
      tuckr

      # Net Diagnostic
      mtr
      dnsutils
      inetutils

      # Android tools
      android-tools

      # Monitoring
      smartmontools

      # Disk
      parted
      ntfs3g
      exfatprogs # for gparted exfat support

      # Archivers
      # rar
      unzip
      zstd
      zip
      #xarchiver

      # Net
      ipset
      iptables
      nftables
      openssl

      # To save
      tuios
      bluetui
      speedtest-cli
      # jocalsend
      tlrc
      lazyssh
      mcat
      snitch
      whosthere
      devenv

      # Test
      rgx
      net-tools
      usbtree
      iperf3
      glow
      # lazydocker
      # dtop
      # framework-tool-tui
    ];
  };
  environment.variables.EDITOR = "fresh";
  programs = {
    # nix-ld stub для запуска generic-linux бинарей без FHS-обёртки.
    # Включается в первую очередь ради herdr-web-ui plugin на rydiwo (и
    # на всякий случай на сапфире): plugin проверяет PATH на bun, и если
    # не находит, скачивает свой runtime в
    # ~/.local/share/herdr-web-ui/install.<hash>/runtime/bin/bun. Этот bun
    # динамически слинкован для generic linux (glibc), и на NixOS stub
    # `ld` без `nix-ld` отказывается его запускать с ошибкой «NixOS cannot
    # run dynamically linked executables intended for generic linux
    # environments out of the box». Системный bun (`pkgs.bun` из
    # home/modules/herdr-runtime.nix) эту проблему не решает — plugin
    # использует **свой собственный** runtime manager (path-pattern
    # `install.<hash>/`), не fallback на PATH.
    #
    # `stdenv.cc.cc.lib` даёт glibc + libstdc++ + libgcc_s — минимум,
    # чтобы glibc-based бинари стартовали. Если конкретный плагин
    # потребует ещё (zlib, openssl, etc.) — расширять
    # `programs.nix-ld.libraries` по факту ldd-проверки.
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ stdenv.cc.cc.lib ];
    };
    justray = {
      enable = false;
    };
    nano = {
      enable = true;
      nanorc = ''
        set nowrap
        set tabstospaces
        set tabsize 2      
      '';
      syntaxHighlight = true;
    };
    yazi = {
      enable = false;
      plugins = {
        inherit (pkgs.yaziPlugins)
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
      settings = {
        yazi = {
          mgr.ratio = [
            1
            1
            4
          ];
        };
        keymap = {
          mgr.prepend_keymap = [
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
        theme = {
          flavor = {
            light = "nord";
            dark = "nord";
          };
        };
      };
    };
    git = {
      enable = true;
      config = {
        user = {
          name = xlib.device.username;
          email = "oqyude@gmail.com";
        };
        pull = {
          rebase = true;
        };
      };
    };
    lazygit.enable = true;
    bat.enable = true;
    # command-not-found.enable = false;
    # nix-index.enable = true;
    nh = {
      enable = true;
      flake = "/etc/nixos";
      clean = {
        enable = true;
        extraArgs = "--keep 2 --keep-since 2d";
        dates = "daily";
      };
    };
  };
}
