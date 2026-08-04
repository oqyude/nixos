{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    tuned = {
      enable = true;
    };
    auto-cpufreq.enable = false;
    power-profiles-daemon.enable = lib.mkForce false;
    throttled.enable = false;
  };

  environment = {
    systemPackages = with pkgs; [
      cpupower-gui
    ];
  };
}
