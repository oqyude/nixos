{
  config,
  pkgs,
  xlib,
  ...
}:
{
  # services.zapret = {
  #   enable = true;
  #   params = [
  #     "--dpi-desync=fake,disorder2"
  #     "--dpi-desync-ttl=1"
  #     "--dpi-desync-autottl=2"
  #   ];
  # };

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
      zapret
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
      ExecStart = ''
        /run/current-system/sw/bin/bash ${xlib.dirs.user-services}/zapret/main_script.sh -nointeractive
      '';
      ExecStop = ''
        /run/current-system/sw/bin/bash ${xlib.dirs.user-services}/zapret/stop_and_clean_nft.sh
      '';
      # ExecStopPost = ''
      #   /run/current-system/sw/bin/echo  "Сервис завершён"
      # '';
      PIDFile = ''
        /run/zapret_discord_youtube.pid
      '';
      # Restart = "on-failure";
      # RestartSec = "5s";
    };
  };
}
