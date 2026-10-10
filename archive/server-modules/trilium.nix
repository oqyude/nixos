{
  config,
  xlib,
  ...
}:
let
  sourceDir = "${xlib.dirs.services-mnt-folder}/trilium";
in
{
  services.trilium-server = {
    enable = false;
    nginx = {
      enable = true;
      hostName = "trilium";
    };
    host = "0.0.0.0";
    dataDir = "${sourceDir}";
  };

  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "z" sourceDir "0750" "trilium" "trilium")
  ];
}
