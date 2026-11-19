# nginx для всех хостов: пакет из master-инпута nixpkgs.
#
# Причина — CVE-2026-123007 (HTTP/2 flow control, heap buffer overflow,
# CVSS 3.1 = 8.1, CVSS 4.0 = 9.2): уязвимы 1.30.0–1.30.6 и 1.31.0–1.31.8,
# исправлено в 1.30.7 / 1.31.9.
#
# Наш пин nixos-unstable на 2026-11-19 отдаёт nginxMainline 1.31.8, то есть
# пакет из `pkgs.nginxMainline` уязвимость НЕ закрывает. В master-инпуте
# (`nixpkgs-master` в flake) уже 1.31.9 — берём пакет оттуда, пока фикс не
# доедет до unstable.
#
# Модуль общий: его импортируют и `defaultModule`, и `strictModule`, поэтому
# правило действует на всех NixOS-хостах (sapphira, rydiwo, vds), а не только
# на том, где nginx терминирует публичный TLS.
{ pkgs, inputs, ... }:
{
  services.nginx.package =
    inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.nginxMainline;
}
