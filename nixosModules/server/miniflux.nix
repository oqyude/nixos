{
  config,
  inputs,
  xlib,
  ...
}:
{
  services.miniflux = {
    enable = true;
    config = {
      ADMIN_USERNAME = "";
      CLEANUP_FREQUENCY = 48;
      LISTEN_ADDR = "0.0.0.0:6061";
    };
    # adminCredentialsFile = "${inputs.zeroq-credentials}/services/miniflux/admin-pass.txt";
    adminCredentialsFile = config.sops.secrets.minifluxenv.path;
  };

  sops.secrets.minifluxenv = {
    sopsFile = ./secrets/miniflux.env;
    # key = null;
    owner = "miniflux"; 
    group = "miniflux";
    mode = "0600";
  };
}
