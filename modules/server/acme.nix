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
        email = "oqyude@gmail.com";
      };
      # certs = {
      #   "home.arpa" = {
      #     email = "oqyude@zeroq.su";
      #     domain = "*.home.arpa";
      #     server = "https://localhost:9000/acme/acme/directory";
      #     listenHTTP = ":80";
      #     dnsProvider = null;
      #   };
      #   # "turn.home.arpa" = {
      #   #   listenHTTP = "127.0.0.1:80";
      #   #   group = "turnserver";
      #   # };
      # };
    };
  };
}
