# zeroq-config/flake.nix
{
  description = "Zeroq variables and configurations";

  outputs = import ./vars.nix;

    # Опционально: можно добавить модуль для NixOS/Home Manager
    #nixosModule = { lib, ... }: {
    #  options.zeroq = lib.mkOption {
    #    default = self.lib;
    #    type = lib.types.attrs;
    #  };
    #};
  };
}
