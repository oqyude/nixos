{
  config,
  lib,
  ...
}:
lib.mkIf config.xlib.ssh.enable {
  services.openssh = {
    enable = true;
    allowSFTP = true;
    openFirewall = lib.mkDefault false;
    hostKeys = [
      {
        path = "/etc/ssh/id_ed25519";
        type = "ed25519";
      }
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
      UsePAM = true;
    };
  };
}
