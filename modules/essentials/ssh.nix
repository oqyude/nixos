{
  config,
  lib,
  ...
}:
{
  options.host.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the SSH server with the shared config below.";
    };
  };

  config = lib.mkIf config.host.ssh.enable {
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
  };
}
