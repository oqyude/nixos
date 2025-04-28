{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.zapret = {
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
      WorkingDirectory = ${inputs.zapret.bash-dir}; # "/etc/nixos/modules/software/zapret"
      ExecStart = "/run/current-system/sw/bin/bash ./main_script.sh -nointeractive";
      ExecStop = "/run/current-system/sw/bin/bash ./stop_and_clean_nft.sh";
    };
  };




#   systemd.services.zapret = {
#     description = "Zaaaapret";
#     unitConfig = {
#       After = [ "network-online.target" ];
#       Wants = [ "network-online.target" ];
#     };
#     wantedBy = [ "multi-user.target" ];
#     serviceConfig = {
#       Type = "simple";
#       Restart = "on-failure";
#       RuntimeDirectory = "zapret";
#       User = "root";
#       WorkingDirectory = "/etc/nixos/modules/software/zapret";  # Замените на реальный путь
#       Environment = "PATH=${pkgs.nftables}/bin:${pkgs.git}/bin:${pkgs.systemd}/bin:/run/wrappers/bin";
#       ExecStart = "/run/current-system/sw/bin/bash ./main_script.sh -nointeractive";
#       ExecStop = "/run/current-system/sw/bin/bash ./stop_and_clean_nft.sh";
#       ExecStopPost = "${pkgs.coreutils}/bin/echo 'Service stopped'";
#
#
# #       ExecStart = "/run/current-system/sw/bin/bash /etc/nixos/modules/software/zapret/main_script.sh -nointeractive";  # Замените на реальный путь
# #       ExecStop = "/run/current-system/sw/bin/bash /etc/nixos/modules/software/zapret/stop_and_clean_nft.sh";  # Замените на реальный путь
#       #ExecStopPost = "${pkgs.coreutils}/bin/echo 'Service stopped'";
#       #PIDFile = "/run/custom-script.pid";
#     };
# #     script = ''
# #     '';
#   };
}
