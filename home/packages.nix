{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable { system = "x86_64-linux"; };
  last-stable = import inputs.nixpkgs-last-unstable { system = "x86_64-linux"; };
in
{
  home = {
    packages = with pkgs; [
      # Base
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
      _64gram
      obsidian
      reaper
      transmission_4-qt
      lollypop

      (brave.override {
        commandLineArgs = [
          "--password-store=basic" # on purpose to make it break "--password-store=gnome-libsecret"
        ];
      })

      #gamehub
      #itch
      prismlauncher
      lutris

      libsecret
      #zerotierone
      #menulibre

      #edid-decode
      #displaycal
      #argyllcms
    ];
  };
}
