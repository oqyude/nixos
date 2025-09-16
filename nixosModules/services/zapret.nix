{
  config,
  pkgs,
  xlib,
  ...
}:
{
  systemd.services.zapret = {
    enable = true;
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    description = "Custom Script Service";
    path = with pkgs; [
      sudo
      git
      nftables
      iproute2
      coreutils
    ];
    unitConfig = {
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "${xlib.dirs.user-services}/zapret";
      User = "root";
      ExecStart = "${pkgs.bash}/bin/bash ${xlib.dirs.user-services}/zapret/main_script.sh -nointeractive";
      ExecStop = "${pkgs.bash}/bin/bash ${xlib.dirs.user-services}/zapret/stop_and_clean_nft.sh";
      ExecStopPost = ''
        ${pkgs.coreutils}/bin/echo  "Сервис завершён"
      '';
      PIDFile = ''
        /run/zapret_discord_youtube.pid
      '';
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

}
