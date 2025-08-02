{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable { system = "x86_64-linux"; };
  last-stable = import inputs.nixpkgs-last-unstable { system = "x86_64-linux"; };
  stable = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
in
{
  programs = {
    fastfetch.enable = true;
    btop.enable = true;
    mangohud.enable = true;
    keepassxc.enable = true;
    zed-editor = {
      enable = false;
      extensions = [
        "nix"
      ];
      userSettings = {
        "telemetry" = {
          "diagnostics" = false;
          "metrics" = false;
        };
        "ui_font_size" = 20;
        "buffer_font_size" = 26;
        "theme" = {
          "mode" = "system";
          "light" = "Ayu Light";
          "dark" = "Ayu Dark";
        };
      };
    };
  };
  services = {
    kdeconnect.enable = true;
    easyeffects.enable = true;
  };
  home = {
    packages = with pkgs; [
      # Surfing
      # (brave.override {
      #   commandLineArgs = [
      #     "--password-store=basic" # on purpose to make it break "--password-store=gnome-libsecret"
      #   ];
      # })
      brave
      v2rayn

      # Workflow
      #cloudflared
      amdgpu_top
      vscodium
      ayugram-desktop
      vesktop
      gramps
      kdePackages.filelight
      libreoffice-qt6
      localsend
      lollypop
      obsidian
      pdfarranger
      stretchly
      transmission_4-gtk
      vlc
      normcap
      zerotierone
      nextcloud-client

      # (handbrake.overrideAttrs (old: {
      #   configureFlags = old.configureFlags ++ [ "--enable-amf" ];
      #   buildInputs = old.buildInputs ++ [
      #     pkgs.amf
      #     pkgs.ffmpeg-full
      #   ];
      # }))

      #tg
      #reaper

      # Games
      ludusavi
      prismlauncher
      lutris

      # AI
      lmstudio

      # Libs
      #libsecret
    ];
  };
}
