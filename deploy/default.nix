{ inputs, ... }@flakeContext:
let
  mkDeploy = hostname: {
    hostname = "${hostname}";
    profiles.system = {
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.${hostname};
    };
  };
  user = "${inputs.self.nixosConfigurations.default.config.xlib.devices.admin}";
  # user = "${inputs.zeroq-deploy.devices.username}";
  server = "${inputs.zeroq-deploy.devices.server.hostname}";
  vds = "${inputs.zeroq-deploy.devices.vds.hostname}";
  mini-laptop = "${inputs.zeroq-deploy.devices.mini-laptop.hostname}";
in
{
  deploy = {
    sshUser = "${user}";
    user = "root";
    nodes = {
      "${server}" = mkDeploy "${server}";
      "${vds}" = mkDeploy "${vds}";
      "${mini-laptop}" = mkDeploy "${mini-laptop}";
    };
  };
  # This is highly advised, and will prevent many possible mistakes
  checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks inputs.self.deploy
  ) inputs.deploy-rs.lib;
}
