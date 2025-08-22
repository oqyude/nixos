{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  work = import inputs.nixpkgs-master { system = "x86_64-linux"; };
in
{
  environment.systemPackages = [
    work.openai-whisper

    # (work.openai-whisper.override {
    #   torch = pkgs.python313Packages.torch-bin; # Используй бинарный torch с ROCm, чтобы обойти сборочную хуйню
    # })
  ];
  # systemd.tmpfiles.rules = ["L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"];
  # hardware.graphics.extraPackages = with pkgs.rocmPackages; [ clr clr.icd ];

  nixpkgs.config.rocmSupport = true;
}
