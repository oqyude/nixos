{ pkgs }:

let
  pname = "pcbu-desktop";
  version = "3.2.3";

  src = pkgs.fetchurl {
    url = "https://github.com/MeisApps/pcbu-desktop/releases/download/v${version}/PCBioUnlock-x64.AppImage";
    sha256 = "sha256-+NxAm6vhMH51z6BscuFvaMidHN/3tNBR1g+i0q9hjWE=";
  };

in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs =
    pkgs: with pkgs; [
      glib
      nss
      nspr
      libdrm
      libGL
      libxkbcommon
      libX11
      libXcursor
      libXrandr
      libXi
      libXext
      libXfixes
      libXrender
      libXtst
      libxcrypt-legacy
      gtk3
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cups
      dbus
      expat
      pango
      cairo
    ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/${pname}.desktop <<EOF
    [Desktop Entry]
    Name=PCBU Desktop
    Exec=${pname}
    Type=Application
    Categories=Utility;
    EOF
  '';
}
