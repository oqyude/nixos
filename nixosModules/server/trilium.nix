{
  config,
  xlib,
  ...
}:
{
  services.trilium-server = {
    enable = true;
    nginx = {
      enable = true;
      hostName = "trilium";
    };
    dataDir = "/mnt/services/trilium";
  };
  
  systemd.tmpfiles.rules = [
    "z /mnt/services/trilium 0750 trilium trilium -"
  ];
}
