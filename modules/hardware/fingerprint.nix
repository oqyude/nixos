{ inputs, ... }@flakeContext:
let
  pkgs-stable = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
in
{
  config,
  lib,
  pkgs,
  ...
}:
{
  #start on boot
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  services = {
    fprintd = {
      enable = true;
      package = pkgs-stable.fprintd.override {
        libfprint = pkgs-stable.libfprint.overrideAttrs (oldAttrs: {
          version = "git";
          src = pkgs-stable.fetchFromGitHub {
            owner = "ericlinagora";
            repo = "libfprint-CS9711";
            rev = "c242a40fcc51aec5b57d877bdf3edfe8cb4883fd";
            sha256 = "sha256-WFq8sNitwhOOS3eO8V35EMs+FA73pbILRP0JoW/UR80=";
          };
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
            pkgs-stable.opencv
            pkgs-stable.cmake
            pkgs-stable.doctest
            #pkgs-stable.nss
          ];
        });
      };
    };
  };



  #     environment.systemPackages = with pkgs; [
  #     ];

  #     services.fwupd.enable = true;

  #     services.udev = {
  #       enable = true;
  #       extraRules = ''
  #         SUBSYSTEM=="usb", ATTRS{idVendor}=="2541", ATTRS{idProduct}=="0236", MODE="0666", GROUP="plugdev", TAG+="uaccess"
  #       '';
  #     };

  #   nixpkgs.overlays = [
  #     (final: prev: {
  #       libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
  #         version = "git";
  #         src = final.fetchFromGitHub {
  #           owner = "ericlinagora";
  #           repo = "libfprint-CS9711";
  #           rev = "c242a40fcc51aec5b57d877bdf3edfe8cb4883fd";
  #           sha256 = "sha256-WFq8sNitwhOOS3eO8V35EMs+FA73pbILRP0JoW/UR80=";
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
