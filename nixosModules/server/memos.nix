{
  config,
  xlib,
  ...
}:
{
  services.memos = {
    enable = true;
    openFirewall = true;
    settings = {
        MEMOS_MODE = "prod";
        MEMOS_ADDR = "0.0.0.0";
        MEMOS_PORT = "5230";
        MEMOS_DATA = config.services.memos.dataDir;
        MEMOS_DRIVER = "sqlite";
        MEMOS_INSTANCE_URL = "http://0.0.0.0:5230";
    };
    user = "${xlib.device.username}";
    group = "users";
    dataDir = "${xlib.dirs.server-home}/Services/immich";
  };
  
}
