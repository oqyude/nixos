{
  lib,
  pkgs,
  xlib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ../3x-ui
    ../containers/open-webui.nix
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
    ./glances.nix
    ./homebox.nix
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
    ./syncthing.nix
    ./systemd.nix
    ./ttyd.nix
    ./vtimeline.nix
    ./uptime-kuma.nix
    ./engipy-frontend.nix
    ./engipy-backend.nix
    # T16: 14 modules archived to ../archive/{server-modules,containers}/
    # (13 in modules/server/default.nix:37-50, 2 in modules/containers/).
    # T15: kokoro-tts and openhands (not imported) also archived.
    # stirling-pdf.nix was deleted in 5dd7a58 (absorbed into bentopdf.nix).
    # open-webui.nix was never commented — migrated to containers/,
    # still active via ../containers/open-webui.nix above.
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
  systemd.services."3xui-reconfig".serviceConfig.Type = "oneshot";
  systemd.services."3xui-reconfig".serviceConfig.ExecStart =
    lib.getExe config.modules."3x-ui".reconfig;
  systemd.services."3xui-reconfig".serviceConfig.Environment = [
    "PANEL_URL=https://127.0.0.1:2049"
    "PANEL_BASE=@base"
    "PANEL_TOKEN=@api_token"
  ];
  systemd.services."3xui-reconfig".description =
    "Перегенерировать config.json 3x-ui из БД и рестартнуть xray (R1.18).";
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
