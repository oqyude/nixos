{ inputs, ... }@flakeContext:
{
  deploy = {
    sshUser = "oqyude";
    user = "root";
    nodes = {
      sapphira = {
        hostname = "sapphira";
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.sapphira;
        };
      };
      otreca = {
        hostname = "otreca";
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.otreca;
        };
      };
    };
  };
  # This is highly advised, and will prevent many possible mistakes
  checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks inputs.self.deploy
  ) inputs.deploy-rs.lib;
}
