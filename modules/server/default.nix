{
  lib,
  pkgs,
  xlib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
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
    ./engipy.nix
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
  # engipy — FastAPI + SBERT webapp (uvicorn за nginx на
  # engipy.zeroq.su). python311.withPackages тянет torch + sentence-
  # transformers; первый nixos-rebuild на sapphira собирает их ~часы
  # (2 ядра), последующие пересборки берут из кэша. Список
  # зависимостей — точно из nix/engipy.nix проекта, чтобы backend-стек
  # на сервере совпадал с dev-окружением.
  host.engipy = {
    enable = true;
    pythonPackage = pkgs.python311.withPackages (ps: with ps; [
      fastapi
      uvicorn
      pydantic
      pydantic-settings
      sqlalchemy
      numpy
      sentence-transformers
      torch
    ]);
  };
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
