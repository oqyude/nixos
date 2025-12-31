{ inputs, ... }@flakeContext:
let
  mkDeploy = hostname: {
    hostname = "${hostname}";
    profiles.system = {
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.${hostname};
    };
  };
  user = "${inputs.zeroq-deploy.devices.username}";
  server = "${inputs.zeroq-deploy.devices.server.hostname}";
  vds = "${inputs.zeroq-deploy.devices.vds.hostname}";
in
{
  deploy = {
    sshUser = "${user}";
    user = "root";
    nodes = {
      "${server}" = mkDeploy "${server}";
      "${vds}" = mkDeploy "${vds}";
    };
  };
  # This is highly advised, and will prevent many possible mistakes
  checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks inputs.self.deploy
  ) inputs.deploy-rs.lib;
}
