{
  config,
  pkgs,
  xlib,
  ...
}:
{
  systemd = {
    services = {
      nixos-prebuild = {
        description = "Prebuild NixOS closure";
        serviceConfig = {
          CPUQuota = "20%";
          User = "oqyude";
          Group = "users";
          Nice = 10;
          Type = "oneshot";
          WorkingDirectory = "/tmp";    
          Environment = [
            "HOME=/home/oqyude"
          ];
          ExecStart = ''
            ${pkgs.nix}/bin/nix build --no-link /etc/nixos#nixosConfigurations.${config.networking.hostName}.config.system.build.toplevel
          '';
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
    timers = {
      nixos-prebuild = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 04:00:00";
          Persistent = true;
        };
      };
    };
  };
}