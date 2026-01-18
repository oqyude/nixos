{
  lib,
  ...
}:
{
  imports = [
    ../desktop
  ];
  fileSystems."/mnt/sapphira" = {
    device = "192.168.1.20:root";
    fsType = "nfs4";
  };
}
