{
  lib,
  xlib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ../3x-ui
    ./nginx.nix
    ./samba.nix
    ./systemd.nix
    # NetBird is not deployed on the VDS. The module is kept as a scaffold
    # (every option in it is `enable = false`), so this line stays commented
    # and will be validated by .ci/tests/import-graph.py.
    # ./netbird.nix
  ];
  # VDS hosts the public-facing Xray REALITY inbound on container:443,
  # fronted by nginx stream on host:443 → host:15380 → container:443.
  # reality443Forwarding MUST stay true here: modules/vds/nginx.nix
  # routes pubrayx1.zeroq.su/default → 127.0.0.1:15380, which only
  # exists when this mapping is published. (Restored 2026-10-10 after
  # T10/C5 wrongly removed it and broke Xray REALITY.)
  host."3x-ui" = {
    certDomain = "pubray1.zeroq.su";
    reality443Forwarding = true;
  };

  # 3xui-reconfig.service (R1.18, 2026-10-21).
  #
  # Аналогично server'ному юниту, но будит панель Otreca по её публичному
  # адресу с apiToken Otreca. Использование:
  #   sudo systemctl start 3xui-reconfig.service
  # (оба юнита называются одинаково и путаются через `systemctl status
  #  3xui-reconfig.service` — без хоста. Это намеренно: владелец стартует
  # их по очереди; один из них адресует локальную панель, другой — удалённую,
  # и оба лечат одно и то же «сервер крутит старое».)
  systemd.services."3xui-reconfig".serviceConfig.Type = "oneshot";
  systemd.services."3xui-reconfig".serviceConfig.ExecStart =
    lib.getExe config.modules."3x-ui".reconfig;
  systemd.services."3xui-reconfig".serviceConfig.Environment = [
    "PANEL_URL=https://pubray1.zeroq.su"
    "PANEL_BASE=@base"
    "PANEL_TOKEN=@api_token"
  ];
  systemd.services."3xui-reconfig".description =
    "Перегенерировать config.json 3x-ui из БД и рестартнуть xray (R1.18) — вариант для Otreca (публичный домен).";

  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
