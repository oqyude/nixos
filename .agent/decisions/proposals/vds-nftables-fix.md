# Proposal: nftables ruleset для otreca (задача T3 / A3)

**Статус:** proposed (не применён)
**Дата:** 2026-10-09
**Связано с:** T3 (manifest), R1.6 (project-rules.md), `configurations/vds.nix:67-92`

## Контекст

`configurations/vds.nix` декларирует nftables-ruleset, но:

1. **Нет финальной политики** на `chain input` (line 75-90) — implicit `accept`
   на «всё остальное». Это проявление R1.6 «явная финальная политика требуется».
2. **`networking.firewall.enable = true` (line 68) и `networking.nftables.enable = true` (line 71)**
   включены одновременно. R1.6 явно фиксирует это как конфликт
   («проверить, кто реально владеет ruleset'ом, перед правкой»).
3. **SSH на 22 открыт только через `networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ]`**
   (line 55). Если Tailscale-демон на otreca упал ИЛИ nftables-ruleset
   перезаписал `firewall.interfaces.*` правила, SSH-мёртв.

## Что произошло при попытке диагностики (2026-10-09)

- `ssh otreca-tailscale` из WSL: **Name or service not known** (нет Tailscale magic DNS в WSL)
- `ssh oqyude@100.64.1.0` (Tailscale IP напрямую): **Connection timed out** (5s)
- `ping 100.64.1.0`: **no response**
- `ssh oqyude@109.248.161.5` (public IP, port 22): **Connection timed out**
- `ping 109.248.161.5`: **OK** (33ms) — хост жив
- Xray-трафик sapphira → otreca `109.248.161.5:443` (XHTTP): **работает** (journal sapphira)

То есть otreca отвечает по 443 (Xray REALITY inbound) и по ICMP, но **port 22
полностью недоступен**. Это и есть T3-баг, видимый снаружи: либо Tailscale-демон
на otreca упал, либо nftables-ruleset дропает 22 на ens3.

## Текущий state (vds.nix:67-92)

```nix
networking = {
  firewall = {
    enable = true;          # ← NixOS-managed firewall (есть allowedTCPPorts и пр.)
    allowPing = true;
  };
  nftables = {
    enable = true;          # ← самописный ruleset
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0;

          # loopback
          iif lo accept

          # уже установленные
          ct state established,related accept

          # РЕЖЕМ SYN СРАЗУ
          tcp flags syn tcp dport {80,443} limit rate 20/second burst 40 packets accept
          tcp flags syn tcp dport {80,443} drop

          # остальное по необходимости   ← НИКАКОГО "остального"
        }
      }
    '';
  };
  firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];   # SSH на Tailscale
  ...
};
services.openssh.openFirewall = false;                          # SSH не открыт в firewall
services.tailscale.openFirewall = true;                         # Tailscale открыт в firewall
```

## Предлагаемое решение (Вариант A — рекомендую)

**Идея:** отдать всё nftables, убрать дубликат, добавить явный `policy drop`.

```nix
networking = {
  # Всё управляется nftables ниже; стандартный firewall выключаем,
  # чтобы не было конфликта приоритетов (R1.6).
  firewall.enable = false;
  firewall.allowedTCPPorts = lib.mkForce [];        # гарантируем пусто
  firewall.interfaces = lib.mkForce {};             # гарантируем пусто
  allowPing = true;                                  # ICMP через nftables ниже

  nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0;
          policy drop;                                # ← ЯВНЫЙ final drop (R1.6 fix)

          # loopback
          iif lo accept

          # уже установленные / связанные
          ct state established,related accept

          # ICMP (нужен для path MTU discovery)
          ip protocol icmp accept

          # traceroute
          udp dport 33434-33534 accept

          # SSH — ТОЛЬКО на Tailscale (R1.6: не на публичном интерфейсе)
          iifname "tailscale0" tcp dport 22 accept

          # Xray REALITY inbound (используется sapphira → otreca как relay)
          tcp dport 443 accept

          # log для диагностики (видно в journal: journalctl -k | grep nft-drop)
          log prefix "nft-drop: " flags all counter drop
        }
      }
    '';
  };

  enableIPv6 = false;
  interfaces.ens3.useDHCP = true;
};
```

### Что меняется

| Было | Станет |
|---|---|
| `firewall.enable = true` + `firewall.interfaces.tailscale0.allowedTCPPorts = [22]` | `firewall.enable = false` (всё через nftables) |
| `chain input` без `policy` (implicit accept) | `policy drop;` явно |
| Нет ICMP-правила (работает через `firewall.allowPing = true`) | `ip protocol icmp accept` в ruleset |
| Нет traceroute | `udp dport 33434-33534 accept` |
| `tcp dport {80,443} rate-limit + drop` (только SYN, не остальной TCP) | `tcp dport 443 accept` (только 443, 80 закрыт) |
| Нет `log` правила | `log prefix "nft-drop: " ... drop` для отладки |

### Что НЕ меняется

- `services.openssh.openFirewall = false` (остаётся — SSH не открываем через firewall, потому что firewall выключен)
- `services.tailscale.enable = true; openFirewall = true` (Tailscale-интерфейс создаётся и маршрутизируется NixOS, openFirewall не имеет эффекта при `firewall.enable = false` но оставлен для ясности)
- `enableIPv6 = false`
- `interfaces.ens3.useDHCP = true`
- `system.stateVersion = "25.05"`

## Альтернативы (для полноты)

### Вариант B — минимальный фикс (только закрыть gap)

```nix
networking.nftables.ruleset = ''
  table inet filter {
    chain input {
      type filter hook input priority 0;
      policy drop;                          # ← ТОЛЬКО ЭТО
      ...остальное как было...
    }
  }
'';
```

- **Плюс:** минимальное изменение.
- **Минус:** не разрешает конфликт `firewall.enable` + `nftables.enable`. Если NixOS при apply добавит правила из firewall-блока после nftables — поведение непредсказуемо.

### Вариант C — задокументировать, не править

Дописать в `configurations/vds.nix` комментарий-предупреждение; создать ADR
в `.agent/decisions/0002-nftables-vds-gap.md`.

- **Плюс:** zero risk, сдвигает проблему.
- **Минус:** проблема остаётся; deploy-rs всё ещё может случайно стереть ruleset при apply.

## Деплой

**Предусловие:** SSH-доступ на otreca должен быть восстановлен. Варианты:
- Через VDS-провайдера (KVM/IPMI/serial console)
- Если Tailscale-демон на otreca мёртв, но SSH-ключ уже на месте — попросить
  провайдера выполнить `systemctl restart tailscaled` или
  `nft flush ruleset && iptables -F` для emergency-разблокировки

**Команда деплоя** (после восстановления SSH):
```bash
deploy . otreca
# или
nixos-rebuild switch --target-host otreca-tailscale --flake .#otreca
```

**Проверка после apply:**
```bash
ssh otreca-tailscale "sudo nft list ruleset | head -30"   # видим policy drop + правила
ssh otreca-tailscale "sudo iptables -L"                   # должно быть пусто
ssh otreca-tailscale "echo OK"                            # SSH работает
ssh sapphira "curl -m 5 https://media.mediavitrina.ru/generate_204 -o /dev/null -w '%{http_code}\n'"
                                                          # Xray REALITY inbound на 443 всё ещё работает
```

## Риск и откат

**Риск:**
- Если восстановление SSH сделано неправильно, можно потерять доступ к otreca
  до конца сессии провайдера. **Это самая опасная часть всей задачи** —
  не сам nftables-fix, а путь к нему.
- Если в ruleset опечатка и блокирует нужное — после `nixos-rebuild switch`
  правила применяются мгновенно. До восстановления SSH-доступа единственный
  путь назад — через KVM/IPMI/serial console провайдера.

**Откат:**
```bash
# Если есть SSH:
ssh otreca-tailscale "sudo nixos-rebuild switch --rollback"

# Если SSH потерян:
#   → KVM/IPMI провайдера → serial console → загрузить предыдущее поколение
#   (systemd-boot: выбрать в GRUB; grub: тоже)
```

## Чеклист перед apply

- [ ] SSH на otreca восстановлен (через Tailscale или KVM)
- [ ] Локальный smoke-test: `nix build .#nixosConfigurations.otreca.config.system.build.toplevel --dry-run` — зелёный
- [ ] Включена serial console в GRUB (если ещё нет) — для emergency recovery
- [ ] Прокатили `nixos-rebuild switch` и проверили:
  - [ ] `nft list ruleset` показывает `policy drop` и все ожидаемые правила
  - [ ] `iptables -L` пуст
  - [ ] SSH через Tailscale работает
  - [ ] Xray REALITY на 443 работает (через sapphira как клиент)
  - [ ] nginx на 80 (если используется на otreca) — открыт, если нет — закрыт
- [ ] После успешного apply: снять snapshot/отметку «стабильная конфигурация», чтобы иметь точку отката

## Обратное (если откатимся)

- Правки только в `configurations/vds.nix:67-92` (ruleset) и
  `configurations/vds.nix:55` (firewall.interfaces.* — очищаем)
- Никаких других файлов не трогаем
- Восстановление = revert `git revert` + `nixos-rebuild switch`

## Связанные задачи

- T3 (A3 в манифесте) — этот proposal закрывает основную часть
- R1.6 — фиксирует конфликт firewall/nftables и требование явной политики
- Возможный follow-up: добавить CI-check «последнее правило chain input —
  policy или явно accept/drop» (кандидат #5 из `analysis-report.md §5`)
