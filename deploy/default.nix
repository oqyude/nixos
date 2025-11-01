{ inputs, ... }@flakeContext:
let
  user = "${inputs.zeroq-vars.devices.username}";
  server = "${inputs.zeroq-vars.devices.server.hostname}";
  vds = "${inputs.zeroq-vars.devices.vds.hostname}";
in
{
  deploy = {
    sshUser = "${user}";
    user = "root";
    nodes = {
      "${server}" = {
        hostname = "${server}";
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.${server};
        };
      };
      "${vds}" = {
        hostname = "${vds}";
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."${vds}";
        };
      };
    };
  };
  # This is highly advised, and will prevent many possible mistakes
  checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks inputs.self.deploy
  ) inputs.deploy-rs.lib;
}
