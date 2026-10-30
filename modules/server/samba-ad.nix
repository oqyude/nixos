# Samba AD DS (Active Directory Domain Controller) — ОПЦИЯ, по умолчанию ВЫКЛЮЧЕНА.
#
# ─────────────────────────────────────────────────────────────────────────────
# Почему модуль вообще нужен
# ─────────────────────────────────────────────────────────────────────────────
# В nixpkgs `services.samba` (пин 31ecbaca / 26.11, samba 4.23.10) НЕТ НИ ОДНОЙ
# опции Active Directory. Проверено по исходникам пина:
#
#   $nixos/modules/services/network-filesystems/samba.nix
#     - нет `enableActiveDirectoryDomainController`
#     - нет `domainName`, нет `realm`, нет `serverRole`
#     - единственный «AD-подобный» переключатель — `settings.global.security
#       = "ads"`, то есть вход в СУЩЕСТВУЮЩИЙ домен как member server,
#       а НЕ «быть» контроллером домена.
#
# И пакет здесь ровно настолько же непригоден:
#
#   $pkgs/servers/samba/4.x.nix
#     enableLDAP ? false            → "--without-ldap --without-ads"
#     enableDomainController ? false → "--without-ad-dc"
#
#   $pkgs/top-level/all-packages.nix
#     samba      = samba4                    # без ldap, без ad-dc
#     samba4Full = samba4.override { … }    # ldap + ad-dc, но заодно
#                                            #   printing(cups) + mdns(avahi)
#                                            #   + cephfs(ceph) — лишний вес
#
# Следствие, проверенное на ЖИВОМ хосте:
#
#   $ ls /nix/store/…-samba-4.23.10/bin/ | grep samba-tool
#   (пусто — в pkgs.samba нет вообще никакого samba-tool)
#
# Файловый сервер, который сейчас работает на sapphira, — это `pkgs.samba`,
# то есть он и в домен зайти не может (нет LDAP, нет ADS).
#
# Значит, для AD DC нужен пакет, в который AD DC реально скомпилирован.
# Берём собственный override — минимальный работающий:
#
#   samba4.override { enableLDAP = true; enableDomainController = true; }
#
# …а не `pkgs.samba4Full`, который ради ненужных AD DC фич притащил бы в
# замыкание cups, avahi и ceph.
#
# ─────────────────────────────────────────────────────────────────────────────
# Что NixOS делает за нас, а что — нет
# ─────────────────────────────────────────────────────────────────────────────
# `samba-tool domain provision` (python/samba/netcmd/domain/provision.py):
#
#   * берёт `realm` из smb.conf, переданного через -s (флага --realm НЕТ!)
#   * пишет <targetdir>/etc/smb.conf:
#       netbios name / workgroup / realm / server role
#       private dir / state directory / cache directory / binddns dir
#       [sysvol]   path = <state directory>/sysvol
#       [netlogon] path = <state directory>/sysvol/<realm>/scripts
#   * создаёт <targetdir>/private/  (sam.ldb, secrets.ldb, idmap.ldb,
#     privilege.ldb, share.ldb, krb5.conf, kdc.conf, tls/, encrypted_secrets.key)
#   * создаёт <targetdir>/state/sysvol/ и каталог netlogon-скриптов
#   * создаёт <targetdir>/bind-dns/ с файлами AD-зон
#
# Отсюда два жёстких требования (обе проверены по исходникам samba):
#
#   1. `paths.sysvol  = lp.get("path", "sysvol")`   и
#      `paths.netlogon = lp.get("path", "netlogon")`.
#      Второй аргумент lp.get() — это ИМЯ ШЕЙРЫ, а не значение по умолчанию:
#      lp.get("path", "sysvol") возвращает `path` секции [sysvol], а
#      lp.get("path", "netlogon") — `path` секции [netlogon]. Если любой из
#      шейров нет → None → MissingShareError → provisioning падает.
#      => наш шаблон smb.conf ОБЯЗАН объявлять обе секции с явным path.
#
#   2. `provision()` перегенерирует smb.conf, только если файла нет или он
#      пуст ("only install a new smb.conf if there isn't one there already").
#      Непустой шаблон используется как есть — это ровно то, что нужно,
#      потому что так задаются `dns forwarder`, `dns port` и `server services`.
#
# Идемпотентность: `samba-tool domain provision` на существующем домене НЕ
# идемпотентен (умирает на существующем sam.ldb). Идемпотентность делаем
# сами: если <state>/private/sam.ldb существует → пропустить, exit 0.
#
# ─────────────────────────────────────────────────────────────────────────────
# Какие порты хочет AD DC (и кто их уже держит на sapphira)
# ─────────────────────────────────────────────────────────────────────────────
#   53/tcp+udp   DNS          ← держит coredns (КОНФЛИКТ)
#   88/tcp+udp   Kerberos KDC
#   135/tcp+udp  RPC endpoint mapper
#   137/udp      NetBIOS name service
#   138/udp      NetBIOS datagram
#   139/tcp      NetBIOS session
#   389/tcp+udp  LDAP
#   445/tcp      SMB          ← держит samba-smbd (файловый сервер) (КОНФЛИКТ)
#   464/tcp+udp  kpasswd
#   636/tcp      LDAPS
#   3268/tcp     Global Catalog
#   49152+       dynamic RPC
#
# Оба конфликта проверяются assertion'ами, а не замалчиваются.
#
# ─────────────────────────────────────────────────────────────────────────────
# Здесь ничего не активируется по умолчанию. При `enable = false` модуль не
# добавляет ни одного юнита, ни одного порта, ни одного пакета и ни одного
# файла в замыкание системы.
# ─────────────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  cfg = config.host.samba-ad;
  inherit (lib) mkIf mkOption types;

  # ── samba с AD DC ─────────────────────────────────────────────────────────
  # НЕ pkgs.samba (нет ad-dc, нет samba-tool) и НЕ pkgs.samba4Full
  # (cups + avahi + cephfs ради фич, которые AD DC не нужны).
  sambaPkg = pkgs.samba4.override {
    enableLDAP = true;
    enableDomainController = true;
  };
  sambaTool = "${sambaPkg}/bin/samba-tool";
  sambaDaemon = "${sambaPkg}/sbin/samba";

  # ── раскладка на диске ────────────────────────────────────────────────────
  # Намеренно НЕ на внешнем диске (xlib.helpers.mkServiceStorage): база
  # контроллера домена должна лежать на локальном надёжном носителе, а
  # внешний том можно выдернуть из-под неё. См. .agent/notes/samba-ad-2026-10-30.md.
  stateDir = "/var/lib/samba-ad";
  smbConfPath = "${stateDir}/etc/smb.conf";
  sysvolPath = "${stateDir}/state/sysvol";
  netlogonPath = "${sysvolPath}/${dnsDomainValue}/scripts";

  # ── идентичность ──────────────────────────────────────────────────────────
  netbiosHost = lib.strings.toUpper xlib.device.hostname;
  netbiosDomain = lib.strings.toUpper cfg.domainName;

  # realm и dnsDomain — два вида одного и того же:
  #   realm     = AD.ZEROQ.SU   (realm Kerberos, верхний регистр)
  #   dnsDomain = ad.zeroq.su   (AD DNS-зона, нижний регистр)
  # Можно задать любой один, второй выводится.
  realm = if cfg.realm != null then lib.strings.toUpper cfg.realm else if cfg.dnsDomain != null then lib.strings.toUpper cfg.dnsDomain else null;
  dnsDomain = if cfg.dnsDomain != null then lib.strings.toLower cfg.dnsDomain else if cfg.realm != null then lib.strings.toLower cfg.realm else null;

  # Заглушки на случай, когда не задано ни то, ни другое (закрыто assertion'ом).
  realmValue = if realm != null then realm else "<unset>";
  dnsDomainValue = if dnsDomain != null then dnsDomain else "<unset>";

  # ── smb.conf, на котором работает DC ──────────────────────────────────────
  # Кладётся в state dir при provisioning (не в /etc/samba — там конфиг
  # файлового сервера, и им нельзя делиться).
  smbConf = pkgs.writeText "samba-ad-smb.conf" ''
    # Generated by modules/server/samba-ad.nix — do not edit by hand.
    # The file server's config lives in /etc/samba/smb.conf and is a
    # different file on purpose: the AD DC must not inherit its shares.
    [globals]
    	netbios name = ${netbiosHost}
    	workgroup = ${netbiosDomain}
    	realm = ${realmValue}
    	server role = active directory domain controller
    	private dir = ${stateDir}/private
    	lock dir = ${stateDir}/lock
    	state directory = ${stateDir}/state
    	cache directory = ${stateDir}/cache
    	binddns dir = ${stateDir}/bind-dns
    	idmap_ldb:use rfc2307 = yes
    ${lib.optionalString (cfg.dnsBackend == "SAMBA_INTERNAL") ''
    	dns port = ${toString cfg.dnsPort}
    ''}${lib.optionalString (cfg.dnsForwarder != null) ''
    	dns forwarder = ${cfg.dnsForwarder}
    ''}${lib.optionalString (cfg.dnsBackend == "NONE") ''
    	# dnsBackend = NONE: DC не поднимает DNS-сервер вовсе, порт 53 он
    	# не трогает. Тогда AD-зоны должны обслуживать кто-то другой —
    	# см. note-файл.
    	server services = -dns
    ''}
    [sysvol]
    	path = ${sysvolPath}
    	read only = no

    [netlogon]
    	path = ${netlogonPath}
    	read only = no
  '';

  # ── provisioning ──────────────────────────────────────────────────────────
  provisionScript = pkgs.writeShellScript "samba-ad-provision" ''
    set -eu

    STATE_DIR="${stateDir}"
    SMB_CONF="${smbConfPath}"
    SMB_CONF_TEMPLATE="${smbConf}"
    ADMIN_PASS_FILE="${cfg.adminPasswordFile or ""}"
    SAMBA_TOOL="${sambaTool}"

    log() { printf '%s\n' "[samba-ad] $*" >&2; }

    # ── идемпотентность ─────────────────────────────────────────────────────
    # samba-tool domain provision НЕ идемпотентен: на существующем домене он
    # умирает на существующем sam.ldb. «Домен уже создан» решается по
    # наличию базы домена, а не повторным запуском инструмента.
    if [ -e "$STATE_DIR/private/sam.ldb" ]; then
      log "domain already provisioned ($STATE_DIR/private/sam.ldb) — nothing to do"
      exit 0
    fi

    if [ -z "$ADMIN_PASS_FILE" ]; then
      log "ERROR: host.samba-ad.adminPasswordFile is not set."
      log "       It must point at a sops secret: config.sops.secrets.<name>.path"
      exit 1
    fi

    if [ ! -r "$ADMIN_PASS_FILE" ]; then
      log "ERROR: admin password file '$ADMIN_PASS_FILE' is missing or unreadable."
      log "       sops-nix.service must have run before this unit."
      exit 1
    fi

    # ── разложить smb.conf из шаблона Nix ───────────────────────────────────
    # samba-tool переписывает smb.conf, только если его нет или он пуст, так
    # что наш шаблон остаётся целым (именно так сохраняются dns forwarder /
    # dns port / server services).
    mkdir -p "$STATE_DIR/etc"
    install -m 0600 "$SMB_CONF_TEMPLATE" "$SMB_CONF"

    # ── пароль администратора ───────────────────────────────────────────────
    # Одна строка, хвостовой перевод строки срезается. Пароля НЕТ ни в Nix-конфиге,
    # ни в сторе, ни в git — он только в sops-секрете.
    ADMIN_PASS=$(head -n 1 "$ADMIN_PASS_FILE")
    if [ -z "$ADMIN_PASS" ]; then
      log "ERROR: admin password file '$ADMIN_PASS_FILE' is empty."
      exit 1
    fi

    log "provisioning: realm=${realm} domain=${netbiosDomain} dns-backend=${cfg.dnsBackend}"

    # ВНИМАНИЕ: --adminpass кладёт пароль в argv samba-tool, где он читается
    # через /proc/<pid>/cmdline на всё время провижининга (несколько минут,
    # один раз). У samba-tool нет опции «прочитать пароль из файла», а его
    # интерактивный режим нельзя совместить с --targetdir — обойти это нельзя.
    # См. note-файл.
    set +e
    "$SAMBA_TOOL" domain provision \
      --realm="${realm}" \
      --domain="${netbiosDomain}" \
      --server-role=dc \
      --dns-backend="${cfg.dnsBackend}" \
      --targetdir="$STATE_DIR" \
      --use-rfc2307 \
      --adminpass="$ADMIN_PASS" \
      -s "$SMB_CONF"
    rc=$?
    set -e
    unset ADMIN_PASS

    if [ "$rc" -ne 0 ]; then
      log "ERROR: samba-tool domain provision failed (exit $rc)"
      exit "$rc"
    fi

    log "provisioning finished"
  '';
in
{
  options.host.samba-ad = {
    enable = lib.mkEnableOption ''
      Поднять на этом хосте Samba Active Directory Domain Controller.

      По умолчанию выключено. Включение поднимает настоящий AD DC (Kerberos
      KDC, LDAP, SMB-сервер для sysvol и — если dnsBackend = "NONE" не
      задан — собственный DNS-сервер на порту 53). Конфликтует с обычным
      файловым samba на том же хосте (оба хотят TCP/445) и с coredns (оба
      хотят 53); оба конфликта проверяются assertion'ами, а не обходятся.
    '';

    domainName = mkOption {
      type = types.str;
      default = "ad";
      example = "ad";
      description = ''
        NetBIOS-имя домена (в smb.conf — `workgroup`). Модуль приводит его
        в верхний регистр. Не более 15 символов, только [A-Z0-9_-].
        Не должно совпадать с NetBIOS-именем самого хоста.

        Дефолт "ad" соответствует предложенному realm "AD.ZEROQ.SU".
      '';
    };

    realm = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "AD.ZEROQ.SU";
      description = ''
        Kerberos realm / AD DNS-домен, верхний регистр. Например "AD.ZEROQ.SU".

        Оставьте null, чтобы вывести его из `dnsDomain`. Хотя бы одно из
        `realm` и `dnsDomain` должно быть задано: угадывать имя домена
        нельзя — это решение владельца, а не модуля.

        Обратите внимание: AD DNS-зона — это ПОДЗОНА той зоны, которую
        сейчас отдаёт этот хост (coredns владеет "zeroq.su"). "AD.ZEROQ.SU"
        означает, что AD владеет "ad.zeroq.su", а coredns остаётся владельцем
        "zeroq.su"; делегация — решение владельца, не модуля.
      '';
    };

    dnsDomain = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "ad.zeroq.su";
      description = ''
        AD DNS-зона, нижний регистр. Выводится из `realm`, если null.

        Это та зона, которую создаёт samba-tool и на которую AD-клиенты
        должны быть направлены за SRV-записями (_ldap._tcp, _kerberos._udp, …).
      '';
    };

    adminPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/samba-ad-admin";
      description = ''
        Путь к файлу с паролем администратора домена.

        Это должен быть sops-секрет: `config.sops.secrets.<name>.path`.
        Пароль читается в рантайме провижининга и никогда не попадает в
        Nix-конфигурацию, в стор и в git.

        Samba требует минимум 7 символов и разумной сложности
        (заглавная, строчная, цифра, спецсимвол).
      '';
    };

    dnsForwarder = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.168.1.1";
      description = ''
        Верхний резолвер для всего, чего не знает AD DNS — пишется в smb.conf
        как `dns forwarder`.

        Имеет смысл только при dnsBackend = "SAMBA_INTERNAL". Без него AD DNS
        только авторитативен, и рекурсия не работает.
      '';
    };

    dnsBackend = mkOption {
      type = types.enum [
        "SAMBA_INTERNAL"
        "NONE"
      ];
      default = "SAMBA_INTERNAL";
      description = ''
        "SAMBA_INTERNAL" — DC поднимает собственный DNS-сервер (AD-зоны лежат
        в его базе). Так делает настоящий AD DC, и ему нужен свободный порт
        53 — который на этом хосте держит coredns.

        "NONE" — DC не поднимает DNS-сервер вовсе (`server services = -dns`).
        Тогда AD-зоны не создаются, и без другого DNS-сервера ни один клиент
        не введёт домен. Используйте, когда DC не должен трогать 53, — но
        сначала прочитайте note-файл.
      '';
    };

    dnsPort = mkOption {
      type = types.port;
      default = 53;
      description = ''
        Порт встроенного AD DNS (smb.conf `dns port`).

        Поднятие его уводит AD DNS с 53, и coredns может его сохранить, — но
        AD-клиенты ждут DNS на 53, значит coredns должен пересылать AD-зоны
        на этот порт. Это не бесплатно; см. note-файл.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Открыть порты AD DC в файрволе NixOS.

        По умолчанию false: на этом парке файрвол — роутер
        (firewall.enable = false сделано намеренно — см. подтверждённые
        инварианты проекта).
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = realm != null;
        message = ''
          host.samba-ad: нужно задать либо `realm` (например "AD.ZEROQ.SU"),
          либо `dnsDomain` (например "ad.zeroq.su"). Имя домена — решение
          владельца; модуль не будет его угадывать.
        '';
      }
      {
        assertion = cfg.adminPasswordFile != null;
        message = ''
          host.samba-ad: нужно задать `adminPasswordFile`. Это должен быть
          sops-секрет (config.sops.secrets.<name>.path). Без него samba-tool
          сгенерирует случайный пароль Administrator, который никто не
          узнает.
        '';
      }
      {
        assertion = cfg.adminPasswordFile == null || !(lib.hasPrefix "/nix/store" cfg.adminPasswordFile);
        message = ''
          host.samba-ad: `adminPasswordFile` указывает в Nix-стор
          (${cfg.adminPasswordFile or ""}). Пароль в сторе читается всеми и
          попадает в историю git. Нужен sops-секрет.
        '';
      }
      {
        assertion = lib.match "[A-Za-z0-9_-]{1,15}" netbiosDomain != null;
        message = ''
          host.samba-ad: `domainName` ("${cfg.domainName}") — недопустимое
          NetBIOS-имя домена: 1-15 символов из [A-Za-z0-9_-].
        '';
      }
      {
        assertion = netbiosDomain != netbiosHost;
        message = ''
          host.samba-ad: `domainName` ("${cfg.domainName}") не должен совпадать
          с NetBIOS-именем самого хоста ("${netbiosHost}") — samba отказывается
          провижинить такой домен.
        '';
      }
      {
        assertion =
          cfg.dnsBackend != "SAMBA_INTERNAL"
          || cfg.dnsPort != 53
          || !config.services.coredns.enable;
        message = ''
          host.samba-ad: КОНФЛИКТ ПОРТА 53. Встроенный DNS AD DC
          (dnsBackend = "SAMBA_INTERNAL", dnsPort = 53) и coredns оба хотят
          TCP/53 и UDP/53 на всех интерфейсах; порт может быть только у
          одного. coredns сейчас отдаёт зоны "zeroq.su" и "home.arpa" всей
          домашней сети — его остановка уронит все имена *.zeroq.su
          (nextcloud, gitea, immich, authelia, …).

          Выберите одно:
            * запустить AD DC на хосте, где порт 53 свободен (рекомендуется);
            * dnsBackend = "NONE" — DC не поднимает DNS, но тогда AD-зоны не
              существуют и ни один клиент не введёт домен;
            * dnsPort = 5353 — AD DNS уходит с 53, но AD-клиентам нужен DNS
              на 53, значит coredns должен пересылать AD-зоны
              (ad.zeroq.su и SRV-зоны _ldap/_kerberos) на него.
        '';
      }
      {
        assertion =
          !(config.services.samba.enable && config.services.samba.smbd.enable);
        message = ''
          host.samba-ad: КОНФЛИКТ ПОРТА 445. AD DC обязан отдавать sysvol по
          SMB (без этого не работает групповая политика), поэтому DC занимает
          TCP/445 — а services.samba.smbd (файловый сервер) на этом хосте уже
          включён и тоже занимает TCP/445. Два процесса не могут владеть
          одним портом.

          Выберите одно:
            * запустить AD DC на отдельном хосте;
            * выключить файловый сервер здесь (services.samba.enable = false)
              и раздавать шары из smb.conf самого DC.
        '';
      }
    ];

    # ── provisioning ───────────────────────────────────────────────────────
    systemd.services.samba-ad-provision = {
      description = "Samba AD DC: provision the domain (idempotent)";
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [
        "network-online.target"
        "sops-nix.service"
      ];
      before = [ "samba-ad.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.RequiresMountsFor = [ stateDir ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${provisionScript}";
        WorkingDirectory = stateDir;
        # Провижининг пишет базу домена; его нельзя убить на полпути по таймауту.
        TimeoutStartSec = "30min";
      };
    };

    # ── сам DC ──────────────────────────────────────────────────────────────
    systemd.services.samba-ad = {
      description = "Samba AD DC (Kerberos KDC, LDAP, DNS, sysvol over SMB)";
      after = [
        "network-online.target"
        "samba-ad-provision.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "samba-ad-provision.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.RequiresMountsFor = [ stateDir ];
      serviceConfig = {
        # `samba` умеет systemd-нотификации (lib/util/become_daemon.c) —
        # именно так сделан upstream-ный samba.service.
        Type = "notify";
        ExecStart = "${sambaDaemon} --foreground --no-process-group -s ${smbConfPath}";
        WorkingDirectory = stateDir;
        LimitNOFILE = 16384;
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    # ── пакеты ──────────────────────────────────────────────────────────────
    environment.systemPackages = [
      sambaPkg
    ];

    # ── файрвол ─────────────────────────────────────────────────────────────
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        53
        88
        135
        389
        445
        464
        636
        3268
      ];
      allowedUDPPorts = [
        53
        88
        135
        137
        138
        389
        464
      ];
    };
  };
}
