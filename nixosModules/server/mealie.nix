{
  config,
  ...
}:
{
  services.mealie = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9000;
    database.createLocally = true;
    settings = {
      ALLOW_SIGNUP = "true";
    };
  };
}
