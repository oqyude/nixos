{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
{
  systemd.services.zapret = {
    enable = true;
    description = "zapret complete";
    unitConfig = {
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    wantedBy = [ "multi-user.target" ];
    path = [ "/run/current-system/sw" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      User = "root";
      WorkingDirectory = "${inputs.zapret.script-dir}";
      ExecStart = "/run/current-system/sw/bin/bash ./main_script.sh -nointeractive";
      ExecStop = "/run/current-system/sw/bin/bash ./stop_and_clean_nft.sh";
    };
  };
  environment = {
    systemPackages = with pkgs; [
      nftables
    ];
  };
}
