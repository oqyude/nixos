{
  lib,
  ...
}:
# Cross-module options: declared here, not in the module that reads them.
#
# An option belongs in this file when at least one context *sets* it while
# another module *reads* it — the reader cannot be the only place that knows
# the option exists. `modules/essentials/ssh.nix` does not belong here: it
# declares and reads `host.ssh.enable` itself, within one module.
{
  # Remote-builder wiring. A coordinator (e.g. sapphira) sets
  # `host.builder.clients` to register remote build machines;
  # a builder host (e.g. the WSL on vetymae) sets `host.builder.enable`
  # to advertise itself. The two halves are intentionally split so a single
  # declaration in configurations/* is enough to flip each side.
  options.host.builder = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Advertise this host as a remote Nix builder and accept builds
        from other machines in the flake over SSH.
      '';
    };
    clients = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = ''
        List of remote Nix build machines this coordinator should
        register via `nix.buildMachines`. Each entry matches the NixOS
        option schema (hostName, sshUser, sshKey, systems,
        supportedFeatures, ...). Two extra attributes are consumed by
        modules/server/builder.nix and stripped before reaching
        `nix.buildMachines`:
          - `proxyCommand` — generates a per-builder Host block in the
            system-wide OpenSSH config (the nix-daemon runs as root and
            cannot see the user's ~/.ssh/config).
          - `hostKeyAlias` — alias used inside that SSH matchBlock.
        A builder reachable on its own (no ProxyCommand needed) omits
        both and gets no SSH matchBlock. Empty by default — opt in by
        setting this list.
      '';
    };
  };

  options.host."3x-ui" = {
    # Domain whose Let's Encrypt cert (at /var/lib/acme/<domain>/)
    # gets mounted read-only into the 3x-ui container so the panel
    # can terminate TLS itself. Set null if 3x-ui serves plain HTTP
    # and TLS is terminated by an upstream nginx.
    certDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "pubray1.zeroq.su";
      description = ''
        Domain whose LE cert should be mounted into the 3x-ui
        container at /root/cert/fullchain.pem and key.pem.
      '';
    };
    # Publish host:15380 → container:443. Only nodes that host an
    # Xray REALITY inbound on container:443 need this (so nginx
    # stream can forward TLS to Xray via 127.0.0.1:15380 while Xray
    # itself sees incoming connections on its configured port 443).
    # Set false on nodes that only run the 3x-ui panel.
    #
    # RESTORED 2026-10-10: this option was wrongly removed by T10/C5.
    # modules/vds/nginx.nix still routes pubrayx1.zeroq.su/default →
    # 127.0.0.1:15380, so without this mapping the nginx stream points
    # at a dead port and Xray REALITY is unreachable.
    reality443Forwarding = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        When true, publish host:15380 → container:443 so Xray
        inside the container can serve REALITY on its real
        configured port 443 (nginx stream forwards 443 → 15380).
      '';
    };
  };

  # pxe-infra — isolated private bridge + MAC-filtered DHCP for PXE
  # VM guests (L2 of docs/ARCHITECTURE.md, see also Q20/Q21/Q23 in
  # docs/OPEN-QUESTIONS.md). Decoupled from the host's primary
  # network stack: dnsmasq is bound to a Linux bridge that lives on
  # a private subnet and never touches the LAN's DHCP server.
  options.pxe-infra = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Master toggle for the PXE infrastructure rig (L2 of
        docs/ARCHITECTURE.md). When enabled, this host gains an
        isolated private bridge and a MAC-filtered DHCP server,
        usable as a stand-alone VM/PXE test bed without touching
        the real LAN.
      '';
    };

    bridge = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "pxe0";
        example = "pxe0";
        description = ''
          Name of the Linux bridge interface that PXE VMs attach
          to. Brought up by a systemd oneshot (idempotent) and
          explicitly unmanaged by NetworkManager so NM does not
          reconfigure it.
        '';
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "10.66.0.1";
        example = "10.66.0.1";
        description = ''
          IP address assigned to the lab host on the private
          bridge. The VM's default route should point here so
          the lab host can always reach the VM via this address.
        '';
      };
      prefixLength = lib.mkOption {
        type = lib.types.int;
        default = 24;
        example = 24;
        description = ''
          CIDR prefix length for the bridge subnet. Must match
          the chosen address (e.g. 10.66.0.1/24). Range and
          gateway options below must all live inside this
          subnet.
        '';
      };
    };

    dhcp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether the bridge-side DHCP server (dnsmasq) should
          run. Set false only if you bring your own DHCP server
          on the bridge.
        '';
      };
      authoritative = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          When true, dnsmasq responds authoritatively to all DHCP
          requests on the bridge (recommended only when nothing
          else on the bridge exists). When false (default),
          dnsmasq answers only MACs listed in `guests` and
          silently drops everything else.
        '';
      };
      rangeStart = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "10.66.0.100";
        description = ''
          Lower bound of a free address pool handed out to guests
          whose MAC is not explicitly listed. Leave null to
          disable the pool and hand out leases only to MACs
          listed in `guests`.
        '';
      };
      rangeEnd = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "10.66.0.200";
        description = ''
          Upper bound of the free address pool. See `rangeStart`.
        '';
      };
      leaseTime = lib.mkOption {
        type = lib.types.str;
        default = "12h";
        example = "1h";
        description = ''
          Default DHCP lease time handed to guests. Short values
          are useful while iterating on the VM's identity; long
          values are useful in steady state.
        '';
      };
      guests = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              mac = lib.mkOption {
                type = lib.types.str;
                example = "52:54:00:12:34:56";
                description = ''
                  MAC address of the guest NIC. Must be unique
                  within the list. dnsmasq answers DHCP only for
                  these MACs unless dhcp.authoritative is true.
                '';
              };
              ip = lib.mkOption {
                type = lib.types.str;
                example = "10.66.0.10";
                description = ''
                  IP address handed to this guest. Must lie
                  inside the bridge subnet.
                '';
              };
              hostname = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "pxe-vm-01";
                description = ''
                  Optional hostname returned to the guest via
                  DHCP. Useful when the image identity phase
                  reads the DHCP-supplied hostname (per
                  docs/OPEN-QUESTIONS.md #A.2).
                '';
              };
            };
          }
        );
        default = [ ];
        description = ''
          Reserved guests: list of MAC ↔ IP mappings (with
          optional hostname). When `dhcp.authoritative` is false,
          dnsmasq answers DHCP only for these guests and silently
          drops everything else.
        '';
      };
    };

    # Where the boot artifacts land on disk. TFTP serves its
    # `tftpboot` subdirectory; HTTP serves its `http` subdirectory.
    # The contents themselves are produced elsewhere (mkosi under
    # build/mkosi/, see docs/OPEN-QUESTIONS.md B.9/B.10) and copied
    # in by whatever deployment step is in use.
    artifacts = {
      root = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/pxe-infra";
        description = ''
          Local directory under which the boot artifacts (kernel,
          initramfs, rootfs/ISO, iPXE image) are expected to live.
          TFTP serves the `tftpboot` subdirectory; HTTP serves the
          `http` subdirectory. The pxe-infra module creates both
          subdirectories at boot via systemd-tmpfiles; it does not
          populate them.
        '';
      };
    };

    # HTTP server: nginx, bound to the bridge IP only. Carries the
    # heavy payloads (kernel, initramfs, rootfs) per
    # docs/ARCHITECTURE.md §L3.
    http = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to enable nginx for HTTP serving of kernel,
          initramfs, and rootfs. Bound to the bridge interface only.
        '';
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 80;
        description = ''
          TCP port for the HTTP server. Bound to the bridge IP only,
          so it does not collide with any other HTTP service on the
          LAN.
        '';
      };
    };

    # TFTP: piggybacks on the same dnsmasq instance as DHCP.
    # ARCHITECTURE.md L3 separates TFTP from HTTP (different roles,
    # different protocol); DHCP+TFTP sharing a daemon is a natural
    # fit and avoids spinning up a second service.
    tftp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether dnsmasq should also serve TFTP for the iPXE boot
          image. Reuses the same daemon and bridge binding as DHCP
          (`bind-interfaces` + `interface=...` carry over). The
          serve root is `artifacts.root/tftpboot`.
        '';
      };
    };

    # VM: a single QEMU/KVM guest that PXE-boots through the
    # bridge. Layer L4 of docs/ARCHITECTURE.md. The guest is
    # intentionally disposable — no persistent disk, no NVRAM
    # persistence, restart on crash — so every run starts from
    # the same state, which is the rig's whole reason to exist.
    vm = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to run a QEMU/KVM guest that PXE-boots through
          the bridge. Disabled by default: enabling it spins up
          the VM on boot, which the user may want to defer until
          the artifact is staged.
        '';
      };
      mac = lib.mkOption {
        type = lib.types.str;
        default = "52:54:00:12:34:56";
        example = "52:54:00:12:34:56";
        description = ''
          MAC address of the guest's NIC. Choose from the
          52:54:00:XX:XX:XX QEMU/OUI range. The same MAC must
          appear in `dhcp.guests` when `dhcp.authoritative` is
          false, otherwise the VM gets no lease.
        '';
      };
      cpus = lib.mkOption {
        type = lib.types.int;
        default = 2;
        example = 4;
        description = ''
          Number of virtual CPUs. Memory and CPU together cap
          which tests can run on the rig (Phase 5 in
          RUNNER-DESIGN.md).
        '';
      };
      memory = lib.mkOption {
        type = lib.types.str;
        default = "2G";
        example = "4G";
        description = ''
          RAM size in QEMU syntax (e.g. `2G`, `512M`). Caps the
          testable memory in Phase 3 (RAM burnin).
        '';
      };
    };

    # iPXE bootloader staging. Bridges the UEFI firmware (which
    # speaks TFTP only) to the L3 HTTP server (which serves the
    # actual image). Without this, the L4 VM gets a DHCP lease
    # but has no filename to TFTP-fetch, so the chain stops there.
    bootloader = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to stage the iPXE EFI binary into the TFTP root
          and write the static boot.ipxe script into the HTTP
          root. Off disables the entire L4 boot chain.
        '';
      };
      ipxeBinary = lib.mkOption {
        type = lib.types.str;
        default = "ipxe.efi";
        description = ''
          Filename of the iPXE EFI binary under the TFTP root.
          The actual binary is taken from `pkgs.ipxe`; this only
          controls the served filename and the `filename` DHCP
          option handed to UEFI firmware. Defaults to the
          universal UEFI binary; `snp.efi` is a smaller variant
          that works on virtio-net only.
        '';
      };
    };
  };
}
