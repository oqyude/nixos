{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs = {
    mangohud.enable = true;
    keepassxc.enable = true;
  };
  services = {
    kdeconnect.enable = true;
    easyeffects.enable = true;
  };
  home = {
    packages = with pkgs; [
      brave
      v2rayn

      # Workflow
      #cloudflared
      # amdgpu_top
      vscodium
      ayugram-desktop
      gramps
      kdePackages.filelight
      localsend
      lollypop
      obsidian
      pdfarranger
      stretchly
      transmission_4-gtk
      #vlc
      #libreoffice-qt6
      #normcap
      #zerotierone
      #nextcloud-client

      # (handbrake.overrideAttrs (old: {
      #   configureFlags = old.configureFlags ++ [ "--enable-vce" ];
      #   buildInputs = old.buildInputs ++ [
      #     pkgs.amf
      #     pkgs.ffmpeg-full
      #   ];
      # }))

      # Games
      #ludusavi
      #prismlauncher
      #lutris

      # AI
      #lmstudio

      # Libs
      #libsecret
    ];
  };
}
