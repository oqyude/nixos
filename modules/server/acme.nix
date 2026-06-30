{
  config,
  pkgs,
  ...
}:
{
  security = {
    acme = {
      acceptTerms = true;
      defaults = {
        email = "oqyude@zeroq.su";
        server = "https://localhost:9000/acme/acme/directory";
        dnsProvider = null;
      };
      # certs = {
      #   # "home.arpa" = {
      #   #   domain = "*.home.arpa";
      #   #   server = "https://localhost:9000/acme/acme/directory";
      #   #   listenHTTP = ":80";
      #   # };
      #   "turn.home.arpa" = {
      #     listenHTTP = "127.0.0.1:80";
      #     group = "turnserver";
      #   };
      # };
    };
  };
}
