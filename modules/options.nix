{
  inputs,
  lib,
  ...
}:
{
  options = {
    xlib = {
      device = {
        type = lib.mkOption {
          type = lib.types.enum [
            "minimal"
            "primary"
            "server"
            "vds"
            "wsl"
          ];
          default = "minimal";
          description = "Type of device for this host.";
        };
        username = lib.mkOption {
          type = lib.types.str;
          default = "${inputs.zeroq.devices.admin}";
          description = "Username for host.";
        };
      };
    };
  };
}
