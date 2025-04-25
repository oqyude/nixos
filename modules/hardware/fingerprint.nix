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


#   nixpkgs.overlays = [
#     (final: prev: {
#       libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
#         version = "git";
#         src = final.fetchFromGitHub {
#           owner = "ericlinagora";
#           repo = "libfprint-CS9711";
#           rev = "03ace5b20146eb01c77fb3ea63e1909984d6d377";
#           sha256 = "sha256-gr3UvFB6D04he/9zawvQIuwfv0B7fEZb6BGiNAbLids=";
#         };
#         nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
#           final.opencv
#           final.cmake
#           final.doctest
#           final.nss
#         ];
#       });
#     })
#   ];


}
