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
  # Only evaluate checks for the systems we actually deploy to. nixpkgs 26.11
  # dropped x86_64-darwin, and deploy-rs's darwin packages throw at eval time
  # (`throwIf ... "Nixpkgs 26.11 has dropped support for x86_64-darwin"`),
  # which broke `nix flake show` / `nix flake check` for the whole flake.
  # Nothing in `deploy` is darwin-specific — it is x86_64-linux only.
  linuxDeployLibs = inputs.nixpkgs.lib.filterAttrs (
    system: _: builtins.match ".*-linux" system != null
  ) inputs.deploy-rs.lib;
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
  ) linuxDeployLibs;
}
