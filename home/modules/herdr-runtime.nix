# `pkgs.bun` для пользовательского PATH.
#
# Зачем отдельный модуль: на sapphira bun исторически приходил через
# `home/modules/opencode.nix` (opencode.nix:339 — для `omo doctor` и
# standalone-вызовов bun/npm/npx в shell); на rydiwo opencode не
# подключали, и bun отсутствовал — herdr-web-ui plugin пытался
# auto-скачать generic-linux bun в
# `~/.local/share/herdr-web-ui/install.<hash>/runtime/bin/bun`, тот
# динамически слинкован и не запускается на NixOS («NixOS cannot run
# dynamically linked executables intended for generic linux
# environments out of the box»).
#
# Теперь это **единственный источник** `pkgs.bun` для пользовательского
# PATH: импортируется и в `home/server.nix` (sapphira), и в
# `home/secondary.nix` (rydiwo). `opencode.nix` оставляет bun только в
# `programs.opencode.extraPackages` (для `--suffix PATH` opencode-wrapped
# env), но не дублирует в `home.packages`.
#
# Note: bun **внутри opencode-wrapped env** (extraPackages в opencode.nix)
# не дублирует и не заменяет bun в shell — это две разные PATH-модификации,
# и opencode-wrapped уже тянет bun из shell PATH через `--suffix PATH`,
# но extraPackages делает это явно для воспроизводимости.
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [ bun ];
}