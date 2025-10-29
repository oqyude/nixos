{ ... }@flakeContext:
{
  nixosConfigurations = {
    atoridu = import ./mini-pc.nix flakeContext; # atoridu
    lamet = import ./mini-laptop.nix flakeContext; # lamet
    otreca = import ./vds.nix flakeContext; # vds
    sapphira = import ./server.nix flakeContext; # sapphira
    wsl = import ./wsl.nix flakeContext; # wsl

    pub-vds = import ./pub-vds.nix flakeContext;
  };
  deploy.nodes = {
    sapphira = {
      hostname = "sapphira";
      deploy = {
        sshUser = "oqyude";
      };
      profiles.system = {
        # user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.sapphira;
      };
    };
  };
  # This is highly advised, and will prevent many possible mistakes
  checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
}
