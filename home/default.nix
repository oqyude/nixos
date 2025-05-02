{ inputs, ... }@flakeContext:
{
  config,
  ...
}:
{
  imports = [
    #./apps/keepassxc.nix
  ];
  home = {
        packages = with pkgs; [
          # Base
          whitesur-gtk-theme
          whitesur-icon-theme
          whitesur-kde
          kdePackages.filelight
          localsend
          ludusavi
          pdfarranger
          libreoffice-qt6
          vlc
          gramps
          stretchly
          nekoray
          discord
          last-stable._64gram
          obsidian
          reaper
          transmission_4-qt
          lollypop

          brave

          prismlauncher
          #gamehub
          #itch
          lutris

          zerotierone
          libsecret

          #edid-decode
          #displaycal
          #argyllcms
        ];
  };
}
