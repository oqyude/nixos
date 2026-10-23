# pxe-infra options.
#
# Declared in this directory rather than in `modules/options.nix`: the option
# belongs to this feature, and `modules/pxe-infra/default.nix` already
# declares `pxe-infra.bootloader.bypassFallback` for the same reason (see the
# note there). NixOS merges option declarations across files, so the two
# halves coexist regardless of which file holds them.
#
# Consequence to keep in mind: these options exist only on hosts that import
# `modules/pxe-infra`. That is intentional, and verified: nothing outside
# modules/pxe-infra/ reads `config.pxe-infra`.
{ lib, ... }:
{

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
      autostart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether the QEMU guest starts on boot. Off by default:
          for script-development iteration, you start it by hand
          (`systemctl start pxe-infra-vm`) and stop it the same
          way. Set this to true if you want the VM up whenever
          rydiwo is up (e.g. while leaving a long unattended
          test running). The systemd unit itself is always
          present when pxe-infra.vm.enable is true, so toggling
          autostart does not require anything beyond this
          option flipping.
        '';
      };
      bootMode = lib.mkOption {
        type = lib.types.enum [ "direct" "pxe" ];
        default = "direct";
        description = ''
          How the guest obtains its boot image.

          `direct` attaches the deployed `latest/alpine-worker.raw`
          as a virtio drive and uses `-boot c`. The OVMF firmware
          finds BOOTX64.EFI in the image's ESP. This is the
          rig's normal mode: the same artifact the PXE chain
          would serve is loaded directly, the boot is
          deterministic, and the firmware chain (TFTP→iPXE→HTTP)
          is not exercised.

          `pxe` uses `-boot n` and does NOT attach the virtio
          drive. The firmware does PXE: dnsmasq hands out DHCP
          and the iPXE binary, iPXE loads boot.ipxe over HTTP,
          boot.ipxe boots the image. This exercises the full
          L3 boot chain. iPXE 2.0.0 currently #GPs at the
          handoff back to OVMF (RIP 0x7EE8A5FC, RAX 0xAF...AF)
          under QEMU 11.x and OVMF 202608, so this mode is for
          reproducing that bug (T10) and verifying fixes; the
          rig itself should run in `direct` mode in steady state.
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

    # Report sink: HTTP endpoint that receives the L4 VM's run
    # report and writes it to disk. Layer L6 of
    # docs/ARCHITECTURE.md. Per the architecture: "Needs to
    # survive the VM disappearing, which rules out anything
    # inside the guest."
    reportSink = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to run the report-sink HTTP service. Listens
          on the bridge IP only and writes accepted reports to
          /var/lib/pxe-infra/reports/<run_id>.json. Disabling
          this drops the only path a report has to land.
        '';
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 8080;
        description = ''
          TCP port for the report sink. Bound to the bridge IP
          only; an unprivileged port so the daemon can run as a
          DynamicUser with no CAP_NET_BIND_SERVICE.
        '';
      };
    };
  };
}
