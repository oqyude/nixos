{
  deviceType = "wsl";
  hostname = "wsl";
  modules = [
    (
      {
        config,
        inputs,
        lib,
        modulesPath,
        pkgs,
        xlib,
        ...
      }:
      {
        imports = [
          inputs.nixos-wsl.nixosModules.default
          inputs.self.nixosModules.default
        ];

        #zramSwap.enable = true;
        services = {
          journald = {
            extraConfig = ''
              SystemMaxUse=512M
            '';
          };
          earlyoom.enable = true;
        };

        hardware = {
          graphics.enable = true;
          # amdgpu.opencl.enable = true;
          # amdgpu.amdvlk.enable = true;
        };

        networking = {
          # nameservers = [
          #   "1.1.1.1"
          #   "8.8.8.8"
          #   "2001:4860:4860::8844"
          #   "2001:4860:4860::8888"
          #   "2606:4700:4700::1111"
          #   "2606:4700:4700::1001"
          # ];
          # networkmanager.enable = true;
          # tempAddresses = "disabled";
          # dhcpcd = {
          #   enable = true;
          #   IPv6rs = true;
          # };
          firewall = {
            enable = false;
            allowPing = true;
          };
          enableIPv6 = true;
          # interfaces.ens3 = {
          #   useDHCP = true;
          #   # ipv4.addresses = [
          #   #   {
          #   #     address = "31.57.158.109";
          #   #     prefixLength = 24;
          #   #   }
          #   # ];
          #   ipv6.addresses = [
          #     {
          #       address = "2a13:7c00:10:6:f816:3eff:fe36:fe1b";
          #       prefixLength = 64;
          #     }
          #   ];
          # };
          # # defaultGateway = {
          # #   address = "31.57.158.1";
          # #   interface = "ens3";
          # # };
          # defaultGateway6 = {
          #   address = "2a13:7c00:10:6::1";
          #   interface = "ens3";
          # };
        };

        wsl = {
          enable = true;
          startMenuLaunchers = true;
          useWindowsDriver = true;
          defaultUser = config.xlib.device.username;
        };

        system.stateVersion = "24.11";
      }
    )
  ];
}
