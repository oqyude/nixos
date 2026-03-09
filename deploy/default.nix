{ inputs, ... }@flakeContext:
let
  mkDeploy = hostname: {
    hostname = "${hostname}";
    profiles.system = {
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.${hostname};
    };
  };
  user = "${inputs.self.nixosConfigurations.default.config.xlib.device.username}";
  server = "sapphira";
  vds = "otreca";
  vds-new = "otreca-new";
  mini-laptop = "rydiwo";
in
{
  deploy = {
    sshUser = "${user}";
    user = "root";
    nodes = {
      "${server}" = mkDeploy "${server}";
      "${vds}" = mkDeploy "${vds}";
      "${vds-new}" = mkDeploy "${vds-new}";
      "${mini-laptop}" = mkDeploy "${mini-laptop}";
    };
  };
  # This is highly advised, and will prevent many possible mistakes
  checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks inputs.self.deploy
  ) inputs.deploy-rs.lib;
}
