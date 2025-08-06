{
  config,
  ...
}:
{
  services.miniflux = {
    enable = false;
    config = {
      CLEANUP_FREQUENCY = 48;
      LISTEN_ADDR = "localhost:6061";
    };
  };
}
