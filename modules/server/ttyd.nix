{
  config,
  lib,
  pkgs,
  ...
}:
# ttyd — web-терминал на 127.0.0.1:7681 (loopback only), за
# reverse-proxy vhost `tty.zeroq.su` (modules/server/nginx.nix).
# Nginx + authelia — единственный ingress; ttyd снаружи недоступен.
#
# Рантайм-наблюдение (Oct 2026): первый прогон с
# `entrypoint = [ pkgs.bashInteractive ]` поднимал bash на slave-pty
# (/dev/pts/N создавался, fd 0/1/2 указывали туда), но bash НЕ входил
# в interactive mode — wchan уходил в `poll_schedule_timeout`, PS1 не
# рисовался, xterm.js канвас оставался пустым. Без явного `-i` и без
# TERM в env systemd-юнита bash имеет право считать себя non-interactive
# даже при isatty(0)=true. Лечится обоими сразу:
#   1. entrypoint = login-shell пользователя + явный `-i`;
#   2. systemd.services.ttyd.environment с TERM и HOME.
#
# Дополнительно: переключаемся с bash на zsh потому, что у `oqyude`
# в /etc/passwd shell = /run/current-system/sw/bin/zsh. Подсовывать
# bash шеллу, чей home настроен на zsh, значит терять dotfiles и
# PATH-модификации, загружаемые при штатном login.
#
# `-l` (login-mode) подгружает полный login-env NixOS: /etc/zshenv,
# /etc/zprofile, ~/.zprofile и через /etc/profile — все
# /etc/profile.d/*.sh, где NixOS выставляет PATH, XDG_DATA_DIRS,
# NIX_PATH и т.п. Без `-l` PATH остаётся тем узким, что в
# systemd-Environment (coreutils/findutils/grep/sed/systemd) — без
# nix/git/docker/man/…, что и было видно в первом прогоне.
#
# Замечание про PATH: NixOS раскладывает login-env по двум НЕСВЯЗАННЫМ
# стекам — bash-стейку (/etc/profile → set-environment с PATH/XDG/
# NIX_PATH/GTK_PATH/INFOPATH/…) и zsh-стейку (/etc/zprofile + /etc/zshrc).
# Zsh сам по себе /etc/profile не source'ит — поэтому PATH внутри
# ttyd-shell остаётся урезанным (только coreutils/findutils/grep/sed/
# systemd от systemd.Environment). Это сознательно НЕ лечится здесь
# (см. todo D2 в docs/arch/todo.md если файл существует): вопрос
# глобальный, должен решаться или через environment.etc."zshrc.local"
# в modules/essentials/, или через ~/.zshenv у пользователя. На этом
# этапе ограничиваемся `zsh -i -l` — оно уже подгружает /etc/zprofile
# (cd /etc/nixos + fastfetch) и /etc/zshrc (oh-my-zsh, aliases,
# compinit, syntax-highlighting). Это то, что просили.
#
# Решения, отступающие от дефолтов upstream `services.ttyd`:
#
#   user = "oqyude"
#     Default — root. С authelia `one_factor` (один пароль) это
#     эквивалент "root-shell за единым паролем". Идём от
#     пользователя-администратора (modules/users.nix: oqyude,
#     isNormalUser, wheel/disk/audio/networkmanager/libvirtd). Цена:
#     ttyd-юзер не правит systemd-юниты напрямую — для этого sudo.
#
#   interface = "127.0.0.1"
#     Биндим исключительно на loopback. Роутер пробрасывает 443 (плюс
#     80/22/8443/22000) на sapphira, но сам ttyd наружу выставлять
#     нельзя: это "SSH на порту 7681 без TLS". Доступ — ТОЛЬКО через
#     127.0.0.1 + nginx-proxy.
#
#   entrypoint = [ userShell "-i" "-l" ]
#     userShell — login-shell пользователя из users.users.<name>.shell
#     (fallback = /run/current-system/sw/bin/bash, если атрибут не
#     выставлен). `-i` форсит interactive mode — без него bash/zsh
#     могут стартовать non-interactive при наличии pty в fd 0.
#     `-l` (login-shell) подгружает /etc/zshenv, /etc/zprofile,
#     /etc/zshrc — login-env zsh-стейка NixOS: cd /etc/nixos +
#     fastfetch, oh-my-zsh, aliases, compinit, syntax-highlighting.
#     PATH остаётся урезанным — см. блок про PATH-замечание выше.
#
#   writeable = true
#     Upstream-assertion требует явного значения.
#
#   checkOrigin = true
#     Без него WebSocket-апгрейд от любого origin проходит — XSS на
#     любом *.zeroq.su vhost превращается в RCE через ttyd.
#
#   maxClients = 0 (default)
#     Решение владельца: без лимита; ttyd разделяет TTY между всеми
#     WS-сессиями, состояние общее.
#
# Шрифт (clientOptions.fontFamily): НЕ задаём. Ttyd генерирует HTML
# с fallback-стеком `courier-new, courier, monospace`, который на
# клиенте отрисовывается через CSS-generic → monospace (Liberation Mono
# на Linux, Menlo на macOS, Consolas/Cascadia на Windows). Fira Code
# (предыдущее значение) требовал установленный на клиенте шрифт; если
# его нет, xterm.js падает на generic mono, но в Canvas API без
# CSS-стека рендеринг становится нестабильным. Явный `monospace` =
# "всегда рисуется системным шрифтом". Если потом захочется Fira
# Code / JetBrains Mono / другой — задать `fontFamily = "Fira Code,
# monospace"` (с trailing monospace, чтобы Canvas нашёл fallback).
#
# systemd-окружение: TERM и HOME пробрасываются явно. systemd по
# дефолту не выставляет TERM (User=oqyude даёт только euid), а
# bash/zsh полагаются на TERM для history-substitution и line-editing.
# HOME нужен zsh для определения `ZDOTDIR` (~/.zshrc и т.п.).
let
  cfg = config.services.ttyd;
  # `users.users.<name>.shell` в NixOS 26.x — это пакет (derivation),
  # а в 24.x был путём. `lib.getExe` умеет оба: derivation → bin/<name>,
  # string → возвращает как есть.
  userShellExe =
    let shell = config.users.users.${cfg.user}.shell or "/run/current-system/sw/bin/bash";
    in if builtins.isString shell then shell else lib.getExe shell;
in
{
  services.ttyd = {
    enable = true;
    port = 7681;
    interface = "127.0.0.1";
    user = "oqyude";
    entrypoint = [ userShellExe "-i" "-l" ];
    writeable = true;
    checkOrigin = true;
    maxClients = 0;
    clientOptions = {
      fontSize = "14";
    };
  };

  systemd.services.ttyd.environment = {
    HOME = "/home/oqyude";
    TERM = "xterm-256color";
    USER = "oqyude";
  };
}
