{
  config,
  lib,
  ...
}:
{
 config = lib.mkIf (config.xlib.device.type == "server") {
    imports = [ ./stirling-pdf.nix ];
  };
}
