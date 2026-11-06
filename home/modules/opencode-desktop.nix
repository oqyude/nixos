# OpenCode v2 + oh-my-opencode-slim на rydiwo (device: secondary, Plasma).
#
# Зачем отдельный модуль, а не переиспользование home/modules/opencode.nix
# ---------------------------------------------------------------------------
# В репозитории есть три разных «opencode-хоста», и это НЕ одно и то же:
#
#   vetymae   (Windows 11, 192.168.1.100) — эталон. opencode 2.0.32 +
#              oh-my-opencode-slim@3.0.5, MCP-набор {webpage (disabled),
#              browser-control, computer-use, genoffice}, авто-одобрение прав,
#              дефолт opencode-go/deepseek-v4.1-flash. Конфиг живёт на
#              Windows и в Nix не описан.
#   sapphira  (server) — тот же opencode, но HEADLESS: там opencode
#              существует только как systemd user service, отдающий web-UI
#              через nginx (opencode.zeroq.su). GUI-инструменты
#              (browser-control/computer-use) на headless-хосте бессмысленны,
#              поэтому в home/modules/opencode.nix их нет.
#   rydiwo    (вот этот модуль) — DESKTOP: Plasma 6 на Wayland (kwin) +
#              XWayland. Здесь нужен тот же плагин и тот же конфиг slim, что
#              на vetymae, плюс browser-control (он работает с ВИДИМЫМ
#              браузером) и рабочий локальный TUI.
#
# Идентичность хоста (2026-11-06, проверено с vetymae):
#   tailscale  100.92.238.19   ← стабильный, именно он стоит в nginx-vhost
#   LAN        192.168.1.102   ← DHCP-lease, уже один раз уезжал на LAMET
#                               (см. ~/.ssh/config на vetymae), поэтому
#                               upstream в vhost'е — tailscale, а не LAN.
#
# Отличия от vetymae (осознанные, не «не хватило времени»):
#   * computer-use MCP — инструмент только под Windows: pywinauto/comtypes
#     и UI Automation, в Windows-only (opencode-computer-use 0.1.2,
#     github.com/rwarx/opencode-computer-use). На NixOS его нет; порт
#     потребовал бы отдельного стека управления X11/Wayland. → ADR-0009.
#   * genoffice MCP — CLI из поставки Electron-приложения GenOffice для
#     Windows; публичного npm-пакета нет (`npm view genoffice` → 404),
#     официальной сборки под Linux тоже нет. → ADR-0009.
#
# Файлы, которые этот модуль кладёт на диск:
#   ~/.config/opencode/opencode.json            <- programs.opencode.settings
#   ~/.config/opencode/cli.json                  <- v2 CLI/TUI preferences
#   ~/.config/opencode/oh-my-opencode-slim.json  <- конфиг slim-плагина
#   ~/.config/opencode/service.json              <- v2 background service (off)
#   ~/.config/opencode/skills/browser-control/SKILL.md   <- из npm-пакета
#   ~/.local/share/opencode/browser-control-extension/   <- из npm-пакета
#
# Ловушки v2 (те же, что на sapphira — см. R1.19 / ADR-0006):
#   * v2 есть только в nixpkgs master ⇒ package из inputs.nixpkgs-master;
#   * дефолт `opencode serve` в v2 — 4097 ⇒ --port 4096 задан явно;
#   * `opencode web` в v2 удалён ⇒ serve отдаёт и API, и web-UI;
#   * v2 НЕ ставит npm-пакеты плагинов сам ⇒ home.activation.installOpencodePlugin;
#   * первый npx-спавн качает пакет и не влезает в MCP-таймаут ⇒
#     home.activation.warmBrowserControlMcp;
#   * фоновый сервис v2 выключен (service.json disabled) — иначе второй
#     сервер на том же 4096 и два писателя в один opencode.db;
#   * `--server` в v2 принимается только ПОСЛЕ подкоманды и не всеми
#     подкомандами ⇒ обёртка `oc`.
{
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  # OpenCode v2 (2.0.32) живёт только в nixpkgs master — тот же приём, что
  # в home/modules/opencode.nix (sapphira) и modules/server/nextcloud.nix.
  masterPkgs = import inputs.nixpkgs-master {
    system = pkgs.stdenv.hostPlatform.system;
  };
  opencodeV2 = masterPkgs.opencode;

  # Версия плагина зафиксирована: v2 обновляет только незапиненные спеки,
  # а на vetymae/sapphira стоит ровно эта.
  pluginSpec = "oh-my-opencode-slim@3.0.5";

  # Модель из реестра opencode, не «на вкус»: id проверяется через
  # `opencode models`, отсутствие в реестре = ProviderModelNotFoundError
  # (см. R1.19 и историю с MiniMax-M3.1-Flash-Preview).
  modelFast = "opencode-go/deepseek-v4.1-flash";

  # Публичное имя vhost'а: используется в --cors и в комментариях.
  # DNS: *.opencodes.zeroq.su — wildcard CNAME на home.zeroq.su
  # (37.128.246.126 = публичный IP sapphira), поэтому отдельной записи в
  # zone не нужно (проверено: rydiwo.opencodes.zeroq.su → 37.128.246.126).
  domain = "rydiwo.opencodes.zeroq.su";

  # browser-control MCP: npm-пакет с MCP-сервером (dist/mcp.js), CLI
  # (dist/cli.js) и распакованным расширением для Chromium (extension/).
  # Версия зафиксирована — репозиторий не любит плавающие версии
  # (.ci/checks.sh #1 про :latest, ADR-0006 про pinning плагинов).
  browserControlSpec = "@opencode-ai/browser-control@0.8.4";

  # nixpkgs ast-grep только один бинарь — ast-grep; скилл плагина
  # (ast-grep) ищет `sg`. Даём оба имени.
  astGrepWithSg = pkgs.runCommandLocal "ast-grep-with-sg" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.ast-grep}/bin/ast-grep $out/bin/ast-grep
    ln -s ${pkgs.ast-grep}/bin/ast-grep $out/bin/sg
  '';

  # Конфиг slim-плагина — зеркало vetymae (~/.config/opencode/oh-my-opencode-slim.json).
  slimConfig = {
    agents = {
      orchestrator = { model = modelFast; };
      explorer = { model = modelFast; };
      oracle = { model = modelFast; };
      designer = { model = modelFast; };
      fixer = { model = modelFast; };
    };
  };

  # Что должно быть в PATH внутри opencode-wrapped env:
  #   nodejs_22 — npx/npm для MCP-серверов и npm-плагинов
  #   ast-grep   — `sg` CLI; скилл плагина его требует
  #   bun        — CLI плагина / `omo doctor`
  #   gh         — GitHub CLI; автоматизация плагина его требует
  extraPackages = [
    pkgs.nodejs_22
    astGrepWithSg
    pkgs.bun
    pkgs.gh
  ];
in
{
  programs.opencode = {
    enable = true;

    package = opencodeV2;

    extraPackages = extraPackages;

    # ~/.config/opencode/tui.json — концепция v1. v2 читает префы CLI/TUI из
    # cli.json (объявлен ниже). tui оставляем пустым, чтобы HM не писал
    # tui.json: в /nix/store он read-only, и авто-миграция tui.json→cli.json
    # на v2 не смогла бы записать файл.
    tui = { };

    # ~/.config/opencode/opencode.json
    #
    # Схема v2: `plugins` (мн.ч.) + `mcp.servers` (вложенно).
    # v1 использовал `plugin` (ед.ч.) и плоскую карту `mcp` — v2 их игнорирует.
    #
    # ВАЖНО: интеграция MCP в HM (programs.mcp.servers -> settings.mcp)
    # выключена (enableMcpIntegration = false по умолчанию). Если её
    # включить, HM подставит v1-плоскую форму и перезапишет блок
    # `mcp.servers` — то самое, чего здесь быть не должно.
    settings = {
      plugins = [ pluginSpec ];

      # Дефолтная модель. На vetymae глобального ключа `model` нет: там TUI
      # помнит последнюю использованную (платную). На свежей БД нечего
      # помнить — без этого ключа v2 сам выберет модель из реестра
      # (opencode/minimax-m3.1-flash-free, бесплатный) и переопределит модель
      # агентов slim-плагина.
      model = modelFast;

      mcp.servers = {
        # webpage MCP выключен — как на vetymae и на sapphira (owner,
        # 2026-11-03: «давай выключим, если browser-control хватит»).
        # Переключатель — `disabled`, НЕ `enabled`: ключа "enabled": false
        # в схеме v2 нет, он молча игнорируется, сервер продолжает стартовать
        # и стоит ~30 с на каждый старт. `timeout` — объект
        # {startup, catalog, execution}, голое число игнорируется.
        webpage = {
          type = "local";
          command = [
            "npx"
            "-y"
            "-p"
            "webpage-mcp@latest"
            "webpage-mcp-stdio"
          ];
          disabled = true;
        };

        # browser-control — единственный GUI-MCP, который работает на
        # NixOS: Node-сервер + расширение для Chromium, которым управляет
        # пользователь в своей сессии. На sapphira (headless) его нет.
        #
        # Таймауты — как на vetymae: startup/catalog 30 с, execution 180 с.
        # Первый запуск сервера поднимает npx-загрузку пакета и его
        # зависимостей (effect, playwright-core, ws) — это не влезает в
        # 30-секундный startup, отсюда home.activation.warmBrowserControlMcp.
        browser-control = {
          type = "local";
          command = [
            "npx"
            "-y"
            "--package=${browserControlSpec}"
            "browser-control-mcp"
          ];
          timeout = {
            startup = 30000;
            catalog = 30000;
            execution = 180000;
          };
        };
      };

      # Авто-одобрение инструментов — как на vetymae и sapphira.
      #
      # Зачем: любой путь вне рабочего каталога сессии поднимает
      # permission `external_directory`, и ход висит в ожидании клика
      # человека. Агент, работающий на хосте (репозиторий, /etc/nixos),
      # из-за этого не может работать без присмотра.
      #
      # Форма — упорядоченный ruleset {action, resource, effect};
      # устаревший объект `permission` с per-tool ask|allow|deny тоже
      # работает, но здесь не используется.
      #
      # Границы: это заменяет клик мышью, а не правила безопасности агента —
      # secrets/, *.env, *.pem и .ssh/ остаются вне зоны по политике.
      permissions = [
        { action = "external_directory"; resource = "*"; effect = "allow"; }
        { action = "read";               resource = "*"; effect = "allow"; }
        { action = "edit";               resource = "*"; effect = "allow"; }
        { action = "bash";               resource = "*"; effect = "allow"; }
        { action = "webfetch";           resource = "*"; effect = "allow"; }
        { action = "websearch";          resource = "*"; effect = "allow"; }
      ];
    };
  };

  # ~/.config/opencode/cli.json — префы CLI/TUI в v2.
  xdg.configFile."opencode/cli.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/v2/cli.json";
    plugins = [ pluginSpec ];
  };

  # ~/.config/opencode/oh-my-opencode-slim.json — конфиг включённого плагина
  # (oh-my-opencode-slim читает свой файл и больше ничего).
  #
  # force = true: файл однажды положили руками, HM отказывается затирать
  # обычный файл и падает с "would be clobbered" — а падает он ДО
  # применения остальных домашних изменений, поэтому активация целиком
  # падает, а объявленная конфигурация не активируется. Содержимое ручного
  # файла и объявленного совпадает, так что перезапись безопасна.
  xdg.configFile."opencode/oh-my-opencode-slim.json" = {
    text = builtins.toJSON slimConfig;
    force = true;
  };

  # ~/.config/opencode/service.json — фоновый сервис v2.
  # Выключаем: дефолтный порт фонового сервиса — тот же 4096, на котором
  # работает наш systemd-юнит, а два сервера на одном хосте дают ещё и два
  # писателя в один ~/.local/share/opencode/opencode.db.
  xdg.configFile."opencode/service.json".text = builtins.toJSON {
    disabled = true;
  };

  home.packages = [
    astGrepWithSg
    pkgs.gh

    # Chromium для browser-control. На rydiwo браузера не было вообще, а
    # MCP им управляет ВИДИМЫМ браузером пользователя: без браузера он
    # бесполезен. Расширение browser-control ставится вручную (unpacked,
    # режим разработчика) — см. ADR-0009 и README модуля.
    pkgs.chromium

    # CLI browser-control — для ручной диагностики (`browser-control doctor`)
    # и настройки расширения. На vetymae это .cmd-шим из глобального npm.
    (pkgs.writeShellScriptBin "browser-control" ''
      export PATH="${lib.makeBinPath extraPackages}:$PATH"
      exec ${pkgs.nodejs_22}/bin/npx -y --package=${browserControlSpec} browser-control "$@"
    '')

    # `oc` — CLI-клиент к УЖЕ запущенному серверу, а не второй сервер.
    #
    # Пароль нужен: API говорит по HTTP basic. Он читается из того же
    # sops-окружения, которое использует юнит (mode 0600, владелец —
    # пользователь), поэтому секрет не попадает в путь /nix/store.
    #
    # `--server` идёт ПОСЛЕ подкоманды (`opencode <cmd> --server <url>`) —
    # так парсит v2. И принимают его НЕ ВСЕ подкоманды: run/attach/tui/api/
    # models/agent — да; mcp/service/auth/serve/plugin — нет
    # ("Unrecognized flag: --server in command opencode plugin list").
    # Пять перечисленных — локальные команды (читают/пишут локальный конфиг
    # и кэш), поэтому вызываются без URL сервера.
    (pkgs.writeShellScriptBin "oc" ''
      export PATH="${lib.makeBinPath extraPackages}:$PATH"
      set -a
      # shellcheck disable=SC1090
      . ${xlib.dirs.opencode-server-env}
      set +a

      server_url="http://127.0.0.1:4096"

      # Локальные подкоманды: сервер не нужен, флаг --server не нужен.
      case "''${1:-}" in
        mcp|service|auth|serve|plugin)
          exec ${opencodeV2}/bin/opencode "$@"
          ;;
      esac

      # Явный --server / --standalone от вызывающего — важнее.
      for arg in "$@"; do
        case "$arg" in
          --server|--server=*|--standalone)
            exec ${opencodeV2}/bin/opencode "$@"
            ;;
        esac
      done

      # Фоновый сервис v2 выключен (service.json), значит сервер — это
      # systemd-юнит. Понятная подсказка лучше стектрейса connection-refused.
      if ! (exec 3<>/dev/tcp/127.0.0.1/4096) 2>/dev/null; then
        echo "oc: opencode server on 127.0.0.1:4096 is not reachable." >&2
        echo "oc: start it with: systemctl --user start opencode-web" >&2
        exit 1
      fi

      exec ${opencodeV2}/bin/opencode "$@" --server "$server_url"
    '')
  ];

  # Ставим npm-пакет плагина в кэш v2.
  #
  # v2.0.32 НЕ ставит пакеты плагинов при старте сервера: сервер грузит
  # только то, что уже лежит в ~/.cache/opencode/npm. На свежем хосте плагин
  # объявлен в opencode.json, но НЕ загружен — `opencode plugin list` пуст,
  # агентов плагина и его MCP (context7, gh_grep) нет, и в логах ни слова
  # почему. Проверено на sapphira 2026-10-21: кэш после первого старта
  # пуст, `opencode plugin add` его наполняет.
  #
  # `plugin add` идемпотентен: плагин уже объявлен в read-only
  # Nix-управляемом opencode.json, команда отвечает "already configured" и
  # только ставит пакет. Ошибки игнорируются осознанно: сорванный прогрев не
  # должен ломать активацию — сервер работает и без плагина.
  home.activation.installOpencodePlugin = lib.hm.dag.entryAfter [ ] ''
    ${opencodeV2}/bin/opencode plugin add ${pluginSpec} >/dev/null 2>&1 || true
  '';

  # Прогрев npx-кеша для browser-control MCP.
  #
  # Первый спавн качает пакет и его зависимости (effect, playwright-core,
  # ws, ...) — это дольше MCP-таймаута startup (30 с), и сервер рапортует
  # «Request timed out» / npm ENOTEMPTY на полузаписанном кэше. Кэш живёт в
  # ~/.npm/_npx, Nix им не управляет, поэтому после каждой чистки кэша
  # проблема возвращается. Прогрев на активации делает первый реальный
  # спавн мгновенным. Ошибка игнорируется осознанно.
  home.activation.warmBrowserControlMcp = lib.hm.dag.entryAfter [ ] ''
    ${pkgs.nodejs_22}/bin/npx -y -p ${browserControlSpec} true >/dev/null 2>&1 || true
  '';

  # Ассеты browser-control из npm-пакета: SKILL.md (чтобы агент знал, как
  # работать с расширением — на vetymae он лежит в
  # ~/.config/opencode/skills/browser-control/SKILL.md) и само расширение
  # (unpacked — его пользователь подгружает в Chromium вручную).
  #
  # Путь npx-кеша нестабилен (хеш от версии/флага), поэтому расширение
  # копируется в постоянное место ~/.local/share/opencode/.
  home.activation.installBrowserControlAssets = lib.hm.dag.entryAfter [ "warmBrowserControlMcp" ] ''
    pkg="$(find "$HOME/.npm/_npx" -maxdepth 4 -type d -path '*@opencode-ai/browser-control' 2>/dev/null | head -n 1 || true)"
    if [[ -n "$pkg" ]]; then
      mkdir -p "$HOME/.local/share/opencode/browser-control-extension" || true
      cp -r "$pkg/extension/." "$HOME/.local/share/opencode/browser-control-extension/" 2>/dev/null || true
      mkdir -p "$HOME/.config/opencode/skills/browser-control" || true
      cp "$pkg/skills/browser-control/SKILL.md" "$HOME/.config/opencode/skills/browser-control/SKILL.md" 2>/dev/null || true
    fi
  '';

  # `opencode serve` как systemd user service.
  # nginx на sapphira проксирует https://rydiwo.opencodes.zeroq.su →
  # 100.92.238.19:4096 (tailscale-адрес rydiwo).
  #
  # --hostname 0.0.0.0 — слушаем все интерфейсы: апстрим заходит по
  # tailscale, а локальный `oc` ходит на 127.0.0.1:4096. Альтернатива
  # (слушать только tailscale-адрес) ломает локальный TUI и «отваливается»
  # при падении tailscale. Открытость наружу прикрыта basic-auth из
  # sops-окружения и тем, что файрвол на хосте выключен (граница — LAN).
  #
  # --port 4096 обязателен: дефолт `opencode serve` в v2 — 4097 (4096 занят
  # фоновым сервисом v2). Без флага vhost отдаёт 502 без ошибок в логах.
  #
  # --cors https://rydiwo.opencodes.zeroq.su — чтобы браузерная сессия
  # доходила до API с этого origin.
  #
  # БЕЗ egress-прокси (в отличие от sapphira, где opencode.ai недоступен
  # напрямую и нужен 127.0.0.1:10808 от 3x-ui): проверено на живом rydiwo
  # 2026-11-06 — GET https://opencode.ai/console/api/v2/config отвечает
  # (401 без токена — то есть маршрут есть), прокси не нужен.
  programs.opencode.web = {
    enable = true;
    environmentFile = xlib.dirs.opencode-server-env;
    extraArgs = [
      "--hostname"
      "0.0.0.0"
      "--port"
      "4096"
      "--cors"
      "https://${domain}"
    ];
  };

  # Ограничения cgroup для opencode-web.
  #
  # На sapphira (5.6 GiB RAM, ~1 GiB baseline) opencode был главной жертвой
  # OOM-киллера: пик 260 MiB – 1.4 GiB, а система перезапускала юнит каждые
  # несколько секунд, маскируя причину. Здесь RAM 11.6 GiB, поэтому потолки
  # выше (2 GiB / 4 GiB), а OOMScoreAdjust -500 (не -900 как на сервере:
  # на десктопе plasma-сессия важнее opencode при нехватке памяти).
  #
  # OOMPolicy "continue": systemd НЕ перезапускает юнит после OOM-килла
  # cgroup'а — иначе вспышка памяти даёт тот же restart-loop.
  #
  # ВНИМАНИЕ: не использовать `serviceConfig = { ... }` — home-manager
  # рендерит это как секцию `[serviceConfig]`, которую systemd молча
  # игнорирует (`Unknown section 'serviceConfig'. Ignoring.`), и защита
  # cgroup'а никогда не вступает в силу (проверено на sapphira, c73a698).
  systemd.user.services.opencode-web.Service = {
    MemoryHigh = "2G";
    MemoryMax = "4G";
    OOMScoreAdjust = -500;
    OOMPolicy = "continue";
  };
}
