{ inputs, ... }@flakeContext:
let
  mkDeploy = hostname: {
    hostname = "${hostname}";
    profiles.system = {
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.${hostname};
    };
  };
  # Login user for every deploy target. Read from the hoisted xlib instead of
  # digging through a built NixOS configuration.
  user = "${inputs.self.xlib.default.device.username}";
  server = "sapphira";
  vds = "otreca";
  mini-laptop = "rydiwo";
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
