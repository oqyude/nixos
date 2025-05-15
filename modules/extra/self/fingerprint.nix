{ inputs, ... }@flakeContext:
let
  pkgs-stable = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
in
{
  config,
  pkgs,
  ...
}:
{
  security.pam.services.login.fprintAuth = false;
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
          ];
        });
      };
    };
  };
}
