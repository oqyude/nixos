{
  config,
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
  # routes the `default` SNI branch (= every name other than
  # pubray1.zeroq.su) → 127.0.0.1:15380, which only exists when this
  # mapping is published. (Restored 2026-10-10 after
  # T10/C5 wrongly removed it and broke Xray REALITY.)
  host."3x-ui" = {
    certDomain = "pubray1.zeroq.su";
    reality443Forwarding = true;
  };

  # 3xui-reconfig.service (R1.18, 2026-10-21; починен 2026-11-16).
  #
  # Аналогично server'ному юниту, но будит панель Otreca по её публичному
  # адресу с apiToken Otreca. Использование:
  #   sudo systemctl start 3xui-reconfig.service
  # (оба юнита называются одинаково и путаются через `systemctl status
  #  3xui-reconfig.service` — без хоста. Это намеренно: владелец стартует
  # их по очереди; один из них адресует локальную панель, другой — удалённую,
  # и оба лечат одно и то же «сервер крутит старое».)
  #
  # ПОЧЕМУ ИМЕННО ПУБЛИЧНЫЙ ДОМЕН (2026-11-16, живой прогон владельца):
  #   * `https://127.0.0.1:8443/pubray/...` → 403 со страницей-декой
  #     «kittenx»: порт 8443 на otreca занят REALITY-инбаундом xray, а не
  #     панелью;
  #   * `https://127.0.0.1:2049/pubray/...` → пустой ответ: панель внутри
  #     контейнера отвечает только на свой `webDomain`
  #     (`pubray1.zeroq.su`), а Host-заголовок локального адреса ему не
  #     соответствует (на sapphira проверено прямо: с Host: x.zeroq.su →
  #     200, без него → 403);
  #   * рабочий путь — `https://pubray1.zeroq.su` (nginx терминирует TLS и
  #     проксирует на 127.0.0.1:2049, Host сохраняется).
  #
  # PANEL_BASE и PANEL_TOKEN — НЕ константы. Это состояние панели: база
  # веб-панели (`webBasePath` в таблице `settings` БД) и её API-токен
  # (`apiToken` там же). Раньше в юните стояли литералы «@base» и
  # «@api_token», которые никто не подставлял, и юнит падал с
  # «Could not resolve host: base» — он не работал НИКОГДА. Теперь их
  # вычисляет обёртка `reconfigRunner` в рантайме (токен не попадает ни в
  # nix store, ни в журнал).
  systemd.services."3xui-reconfig" = {
    description = "Перегенерировать config.json 3x-ui из БД и рестартнуть xray (R1.18) — вариант для Otreca (публичный домен).";
    # Порядок запуска: панель должна быть поднята (БД панели читается из
    # контейнера). `After=` не тянет контейнер за собой — если панель не
    # запущена, юнит упадёт с внятным сообщением.
    unitConfig.After = [ "podman-3xui_app.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe config.modules."3x-ui".reconfigRunner;
      Environment = [
        "PANEL_URL=https://pubray1.zeroq.su"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
