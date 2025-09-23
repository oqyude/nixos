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
        #MEMOS_MODE = "prod";
        MEMOS_ADDR = "127.0.0.1";
        MEMOS_PORT = "5230";
        #MEMOS_DATA = config.services.memos.dataDir;
        MEMOS_DRIVER = "sqlite";
        MEMOS_INSTANCE_URL = "http://localhost:5230";
    };
  };
}
