{
  config,
  lib,
  pkgs,
  ...
}:
{
  # start on boot
#   systemd.services.fprintd = {
#     wantedBy = [ "multi-user.target" ];
#     serviceConfig.Type = "simple";
#   };

  services = {
    fprintd = {
      enable = true;
      #package = pkgs.libfprint;
      #tod.enable = true;
      #tod.driver = pkgs.libfprint-2-tod1-goodix-550a;
    };
  };
#
#   environment.systemPackages = with pkgs; [
#     fprintd
#     open-fprintd
#   ];


  nixpkgs.overlays = [
    (final: prev: {
      libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
        version = "git";
        src = final.fetchFromGitHub {
          owner = "ericlinagora";
          repo = "libfprint-CS9711";
          rev = "c242a40fcc51aec5b57d877bdf3edfe8cb4883fd";
          sha256 = "sha256-WFq8sNitwhOOS3eO8V35EMs+FA73pbILRP0JoW/UR80=";
        };
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          final.opencv
          final.cmake
          final.doctest
          final.nss
        ];
      });
    })
  ];


}
