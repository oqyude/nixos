# Registry of the addresses and ports the fleet talks to.
#
# Why this file exists: the same literal was written in dozens of places
# (192.168.1.20 alone — 41 occurrences) across modules that had to agree on
# it without knowing about each other. A DHCP lease moves, a Tailscale address
# changes, and the copy nobody noticed keeps pointing at the old address. The
# repo already documents that failure mode for the 3x-ui chain (ADR-0003);
# this file is the same idea applied to plain addresses.
#
# How to use it: `xlib.net.hosts.sapphira.lan`. The registry is pure data and
# is injected into every module as `xlib.net` (see lib/xlib/default.nix), so
# it is available both in NixOS modules and in home-manager modules.
#
# Rules for this file:
#   * one address — one name. If a literal appears in two modules, both read
#     it from here.
#   * Loopback (127.0.0.1) and the wildcard (0.0.0.0) are NOT registered:
#     they are language-level constants, not fleet topology, and reading
#     `xlib.net.loopback` would be noise.
#   * A value owned completely by one module (a service's own port) stays in
#     that module. `ports` below holds only the ports that are a contract
#     between two or more modules.
#   * Modules listed under "not migrated" at the bottom keep their literals
#     on purpose — see the note there before touching them.
{
  hosts = {
    # The home server: runs the services, terminates nginx.
    sapphira = {
      lan = "192.168.1.20";
      # Tailscale address, assigned manually (AGENTS.md invariant 4).
      tailscale = "100.64.0.0";
    };

    # Chuwi MiniBook — desktop (secondary).
    rydiwo = {
      # DHCP lease. It already moved to another machine once (LAMET), which is
      # exactly why the tailscale address below is the one used for upstream.
      lan = "192.168.1.102";
      tailscale = "100.92.238.19";
    };

    # Windows workstation — the opencode reference machine. Not described in
    # Nix; only its address is known here.
    vetymae = {
      lan = "192.168.1.100";
    };

    # Other tailnet members publishing an opencode server.
    lamet = {
      tailscale = "100.106.21.39";
    };
    etherea = {
      tailscale = "100.125.228.63";
    };
    dejavu = {
      tailscale = "100.86.134.111";
    };

    # Android device (nix-on-droid), reachable over the LAN on port 8022.
    epral = {
      lan = "192.168.1.101";
    };

    # VPS.
    otreca = {
      public = "109.248.161.5";
      # Previous public address — kept for the `otrea-old` ssh alias.
      publicOld = "217.60.3.12";
      tailscale = "100.64.1.0";
    };

    # Home router: the LAN gateway and the public address behind
    # home.zeroq.su (the wildcard CNAME target for *.opencodes.zeroq.su).
    router = {
      lan = "192.168.1.1";
      public = "37.128.246.126";
    };
  };

  # Public resolvers.
  dns = {
    cloudflare = "1.1.1.1";
    google = "8.8.8.8";
  };

  # Networks, in CIDR form.
  networks = {
    lan = "192.168.1.0/24";
    tailscale = "100.64.0.0/10";
    # Podman's default network and the network tape-rotation creates.
    podman = "10.88.0.0/16";
    podmanTapeRotation = "10.89.0.0/24";
  };

  # Static addresses of containers inside the podman networks above. They are
  # not fleet machines — they only exist inside their own network.
  containerHosts = {
    # tape-rotation backend: the frontend reaches it by this address because
    # the network has no DNS plugin (--add-host).
    tapeRotationBackend = "10.89.0.10";
  };

  # Ports that are a contract between two or more modules.
  ports = {
    # opencode server: the systemd user service on sapphira, the nginx vhost
    # `opencode.zeroq.su`, and the `oc` wrapper on every host.
    opencode = 4096;
    # Authelia forward-auth endpoint — nginx asks it about every protected
    # vhost.
    authelia = 9091;
    # Host-side port that publishes the 3x-ui container's REALITY inbound
    # (nginx stream forwards 443 -> 15380 -> container:443).
    reality3xui = 15380;
    # Egress proxy published by the 3x-ui container on the host loopback.
    httpProxy = 10808;
  };

  # Not migrated, on purpose:
  #   * home/modules/opencode.nix (sapphira) — the working opencode setup of
  #     the owner; AGENTS.md / ADR-0009 forbid refactoring it. Its proxy
  #     environment keeps literal addresses.
  #   * modules/pxe-infra/* — the PXE network has its own option surface
  #     (modules/pxe-infra/options.nix); a second registry for the same
  #     addresses would be a worse problem than the literals it replaces.
  #   * The podman networks of the other containers — assigned by podman
  #     itself; only the two networks above are referenced from two modules.
}
