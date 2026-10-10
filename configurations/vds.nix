# Host: "otreca" (device: vds)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
#
# T3 FIX (minimal, R1.6 only) 2026-10-10:
#   - Explicit `policy drop` on chain input (R1.6 fix — original ruleset
#     had no policy, so it was implicit accept)
#   - Removed `firewall.enable = true` to eliminate the
#     `firewall.*` + `nftables.*` conflict (R1.6)
#   - SSH (22) open on ALL interfaces (no iifname restriction)
#   - Xray REALITY (443) open
#   - ICMP + traceroute (33434-33534) for diagnostics
#   - 80/HTTP closed by default
#   - Log + drop at the end (nft-drop: prefix) for diagnostics
#
# CORRECTED 2026-10-10: removed `iifname "tailscale0"` restriction on
# SSH — owner did not ask for that. SSH is open on ens3 too.
#
# On otreca: management via Tailscale OR public SSH. Public attack
# surface is SSH (22) + Xray REALITY (443).
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
  # SSH is reachable on all interfaces (public + Tailscale). The
  # nftables ruleset below opens 22 explicitly. `openFirewall = false`
  # because we manage the firewall via nftables, not the NixOS
  # firewall module (see `firewall.enable = false` further down).
  services.openssh.openFirewall = false;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  # REMOVED 2026-10-10: networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ].
  # SSH is now opened on ALL interfaces via the nftables ruleset below
  # (`tcp dport 22 accept` — no iifname restriction).
  # Owner corrected: "не помню, чтобы просил ограничивать 22 порт".

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
    # T3 (R1.6 fix): `firewall.enable = false` eliminates the
    # `firewall.*` + `nftables.*` conflict. The `lib.mkForce` on
    # `allowedTCPPorts` and `interfaces` prevents the NixOS firewall
    # module from silently injecting rules that would shadow our
    # nftables ruleset. All filtering is now done by the ruleset below.
    firewall.enable = false;
    firewall.allowedTCPPorts = lib.mkForce [ ];
    firewall.interfaces = lib.mkForce { };
    # `networking.allowPing` was removed because with firewall.enable = false
    # it no longer exists as a top-level option. ICMP accept is handled
    # by the nftables ruleset below (`ip protocol icmp accept`).
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

            # SSH (22) — open on all interfaces (owner: no iifname restriction)
            tcp dport 22 accept

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
