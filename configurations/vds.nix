# Host: "otreca" (device: vds)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
{
  lib,
  modulesPath,
  pkgs,
  xlib,
  inputs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")

    ./disko/vds.nix
    ./hardware/vds.nix

    inputs.self.nixosModules.default
  ];

  boot = {
    # kernelPackages = pkgs.linuxPackages_xanmod_stable;
    hardwareScan = true;
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        useOSProber = false;
        efiSupport = false;
      };
      systemd-boot.enable = lib.mkDefault false;
    };
    kernel.sysctl = {
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_max_syn_backlog" = 4096;
      "net.ipv4.tcp_synack_retries" = 3;
      "net.ipv4.tcp_syn_retries" = 3;
    };
  };

  host.ssh.enable = true;
  # SSH is reachable only over Tailscale (not on the public internet).
  # This otreca VDS is reached by deploy-rs and by oqyude over the
  # tailnet, so exposing 22 to ens3 is pure attack surface.
  services.openssh.openFirewall = false;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  # Open port 22 only on the tailscale interface.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
  networking = {
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    networkmanager.enable = true;
    tempAddresses = "disabled";
    dhcpcd = {
      enable = true;
      IPv6rs = false;
    };
    firewall = {
      enable = true;
      allowPing = true;
    };
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority 0;

            # loopback
            iif lo accept

            # уже установленные
            ct state established,related accept

            # РЕЖЕМ SYN СРАЗУ
            tcp flags syn tcp dport {80,443} limit rate 20/second burst 40 packets accept
            tcp flags syn tcp dport {80,443} drop

            # остальное по необходимости
          }
        }
      '';
    };
    enableIPv6 = false;
    interfaces.ens3 = {
      useDHCP = true;
      # ipv4.addresses = [
      #   {
      #     address = "31.57.158.109";
      #     prefixLength = 24;
      #   }
      # ];
      # ipv6.addresses = [
      #   {
      #     address = "2a13:7c00:6:102:f816:3eff:fe91:6b9e";
      #     prefixLength = 64;
      #   }
      # ];
    };
    # defaultGateway = {
    #   address = "31.57.158.1";
    #   interface = "ens3";
    # };
    # defaultGateway6 = {
    #   address = "2a13:7c00:6:102::1";
    #   interface = "ens3";
    # };
  };

  system = {
    stateVersion = "25.05";
  };
}
