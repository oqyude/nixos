{
  config,
  xlib,
  ...
}:
{
  services.trilium-server = {
    enable = false;
    nginx = {
      enable = true;
      hostName = "trilium";
    };
    host = "0.0.0.0";
    dataDir = "/mnt/services/trilium";
  };

  systemd.tmpfiles.rules = [
    "z /mnt/services/trilium 0750 trilium trilium -"
  ];
}
