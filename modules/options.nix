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
}
