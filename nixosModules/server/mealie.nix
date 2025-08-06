{
  config,
  ...
}:
{
  services.mealie = {
    enable = false;
    listenAddress = "0.0.0.0";
    port = 9000;
  };
}
