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
      # Surfing
      (brave.override {
        commandLineArgs = [
          "--password-store=basic" # on purpose to make it break "--password-store=gnome-libsecret"
        ];
      })
      nekoray

      # Workflow
      _64gram
      discord
      gramps
      kdePackages.filelight
      libreoffice-qt6
      localsend
      lollypop
      obsidian
      pdfarranger
      reaper
      stretchly
      transmission_4-qt
      vlc
      #zerotierone

      # Games
      ludusavi
      #gamehub
      #itch
      prismlauncher
      lutris

      # Libs
      libsecret

      # Display
      #edid-decode
      #displaycal
      #argyllcms
    ];
  };
}
