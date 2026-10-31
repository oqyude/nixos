{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ../3x-ui
    # 2026-10-30: open-webui выключен — контейнер падал (podman-open-webui.service
    # failed), образ 4.69 ГБ тянулся с ghcr.io и авто-обновлялся. Вернуть: раскомментировать.
    # ../containers/open-webui.nix
    ../containers/tape-rotation.nix
    ../pkgs/beets.nix
    ./acme.nix
    ./authelia.nix
    ./bentopdf.nix
    ./builder.nix
    ./calibre-web.nix
    ./chrony.nix
    ./coredns.nix
    ./gitea.nix
    ./gitea-runner.nix
    # 2026-10-30: glances выключен — владельцу не нужен (порт 61208 слушал, openFirewall
    # открывал его наружу). Записи в coredns (glances.zeroq.su/home.arpa) оставлены:
    # указывают в закрытый порт, вреда нет.
    # ./glances.nix
    ./homebox.nix
    # immich — НУЖЕН (владелец, 2026-10-30). Был выключен директором на полчаса
    # и сразу возвращён. Держит ~1.3 ГБ RAM в пике и 2.9 ГБ кэша ML-моделей.
    ./immich.nix
    ./miniflux.nix
    ./navidrome.nix
    ./nextcloud.nix
    ./nginx.nix
    ./nix-serve.nix
    ./onlyoffice.nix
    ./postgresql.nix
    ./power.nix
    ./samba.nix
    # 2026-10-30: Samba AD DS (domain controller) — OPTION, disabled by
    # default. `host.samba-ad.enable = false` adds no unit, no port and no
    # package. Enabling it asserts the two real port conflicts (53 = coredns,
    # 445 = the file server) instead of silently overwriting them.
    ./samba-ad.nix
    ./syncthing.nix
    ./systemd.nix
    ./ttyd.nix
    ./vtimeline.nix
    # 2026-10-30: uptime-kuma выключен — юнит падал по таймауту (failed since 15:09),
    # то есть мониторинг не работал, а рестарты крутились.
    # Вернуть: раскомментировать.
    # ./uptime-kuma.nix
    ./engipy-frontend.nix
    ./engipy-backend.nix
    # T16: 15 modules archived to ../../archive/{server-modules,containers}/
    # (12 in archive/server-modules/, 3 in archive/containers/).
    # This import list carries zero commented-out entries.
    # T15: kokoro-tts and openhands (not imported) also archived.
    # stirling-pdf.nix was deleted in 5dd7a58 (absorbed into bentopdf.nix).
    # open-webui: 2026-10-30 выключен выше (сомнительно: контейнер падал).
  ];
  # Server's 3x-ui is the controller panel at x.zeroq.su (nginx HTTP
  # terminates TLS upstream, no SNI-routing on 443 needed here because
  # there are other vhosts on the same port). Cert is still mounted in
  # case 3x-ui is later reconfigured to terminate TLS itself (e.g. for
  # direct node-API access); nginx doesn't have to use it.
  host."3x-ui".certDomain = "x.zeroq.su";
  # Authelia SSO — currently protects vtimeline.zeroq.su (replaces the
  # previous nginx auth_basic htpasswd). Cookie domain is .zeroq.su so a
  # single Authelia session covers every protected vhost under the zone.
  host.authelia = {
    enable = true;
    cookieDomain = "zeroq.su";
  };

  # ──────────────────────────────────────────────────────────────────────
  # 3x-ui reconfig (R1.18, 2026-10-21).
  #
  # На server (sapphira) контроллер-панель 3x-ui сидит в контейнере, доступна
  # через nginx → `https://x.zeroq.su`. Юнит ниже ровно эту панель и будит:
  #   sudo systemctl start 3xui-reconfig.service
  # POST'ит `/panel/api/server/restartXrayService` через apiToken владельца.
  # Сценарий, который лечит: «панель показывает новое, сервер крутит старое».
  # Правка REALITY в UI меняет БД, но `/app/bin/config.json` сам не
  # переписывается — без этого юнита (или `restartXrayService` руками) ссылки
  # у клиентов тихо ломаются.
  #
  # В otreca аналогичный юнит определён в `modules/vds/default.nix` с
  # другим `PANEL_URL`/`apiToken`.
  systemd.services."3xui-reconfig" = {
    description =
      "Перегенерировать config.json 3x-ui из БД и рестартнуть xray (R1.18).";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe config.modules."3x-ui".reconfig;
      Environment = [
        "PANEL_URL=https://127.0.0.1:2049"
        "PANEL_BASE=@base"
        "PANEL_TOKEN=@api_token"
      ];
    };
  };
  # engipy webapp — split architecture:
  #   - sapphira  : host.engipy-frontend.enable  → nginx vhost (engipy.zeroq.su)
  #                 с /api/* на rydiwo:8000 и / → /var/lib/engipy/web
  #   - rydiwo    : host.engipy-backend.enable   → systemd engipy (uvicorn + ML)
  # Оба модуля импортируются для всех server/deviced хостов, и через
  # host.*.enable выбирается только то, что нужно на конкретной машине.
  # Причина — sapphira слабая (2 cores, 5.6 GB RAM) и не вытянет torch;
  # rydiwo 4 cores / 11 GB держит uvicorn+sentence-transformers без свопа.
  # engipy webapp (uvicorn) тащит python311 + fastapi + pydantic +
  # sentence-transformers. sphinx-9.1.0 не поддерживается для python3.11
  # (см. https://nixos.org/manual/nixpkgs/unstable#sec-problems — unsupportedPython).
  # sphinx не используется в runtime, поэтому глушим evaluation-error до
  # warning. Альтернатива — переезд на pkgs.python312, но проще держать
  # python311 в соответствие с тем, как код собирается локально.
  nixpkgs.config.problems.handlers.sphinx.unsupportedPython = "warn";

  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
