# Host: "otreca" (device: vds)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
#
# T3 FIX APPLIED 2026-10-10 (Option A from
# .agent/decisions/proposals/vds-nftables-fix.md):
#   - Explicit `policy drop` on chain input (R1.6 fix)
#   - Removed `firewall.enable = true` to eliminate the
#     `firewall.*` + `nftables.*` conflict (R1.6)
#   - SSH on port 22 limited to tailscale0 via nftables iifname
#   - ICMP + traceroute explicitly accepted
#   - Xray REALITY on 443 accepted
#   - 80/HTTP closed by default (no nginx here, otreca is relay)
#   - Log + drop at the end (nft-drop: prefix) for diagnostics
#
# On otreca: Tailscale-only management. Public attack surface is
# Xray REALITY on 443 only. Everything else is tailnet-internal.
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
  # NOTE: networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
  # REMOVED 2026-10-10 (T3 Option A): the old `firewall.enable = true` setup
  # conflicted with the custom nftables ruleset (R1.6). The new ruleset
  # opens 22 on tailscale0 directly via `iifname "tailscale0" tcp dport 22 accept`.

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
    # T3 Option A: `firewall.enable = false` to eliminate the
    # firewall.* + nftables.* conflict (R1.6). The mkForce on
    # allowedTCPPorts and interfaces ensures the NixOS firewall
    # module does not silently add rules that would shadow our
    # nftables ruleset. All filtering is now done by the ruleset below.
    firewall.enable = false;
    firewall.allowedTCPPorts = lib.mkForce [ ];
    firewall.interfaces = lib.mkForce { };
    # allowPing removed 2026-10-10 (T3 Option A): with firewall.enable = false,
    # `networking.allowPing` no longer exists as a top-level option. ICMP
    # accept is now handled by the nftables ruleset below
    # (`ip protocol icmp accept`).
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority 0;
            policy drop;

            # loopback
            iif lo accept

            # уже установленные
            ct state established,related accept

            # ICMP (path MTU discovery + diagnostics)
            ip protocol icmp accept

            # traceroute
            udp dport 33434-33534 accept

            # SSH — Tailscale only (R1.6: never on the public interface)
            iifname "tailscale0" tcp dport 22 accept

            # Xray REALITY inbound (treca acts as relay from sapphira via XHTTP)
            tcp dport 443 accept

            # log for diagnostics (journalctl -k | grep nft-drop)
            log prefix "nft-drop: " flags all counter drop
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
