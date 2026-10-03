# sapphira (and any other server-class coordinator) — register remote
# builders, and make sure the nix daemon (running as root) can resolve the
# SSH host alias with its ProxyCommand chain.
#
# The `host.builder.clients` option itself is declared in
# modules/options.nix (cross-module). The actual builder list is set by the
# configuration (e.g. configurations/server.nix) — this module is generic
# over every entry on the list.
{
  config,
  lib,
  ...
}:
let
  # Attributes that belong to the SSH matchBlock only — NOT to
  # `nix.buildMachines` (that schema has no hostKeyAlias/proxyCommand).
  # Strip them before handing the list to nix.buildMachines.
  sshOnlyAttrs = [
    "hostKeyAlias"
    "proxyCommand"
  ];
  forNix = b: removeAttrs b sshOnlyAttrs;
  # After NixOS's nix.buildMachines submodule runs, each entry has all
  # attributes defaulted (protocol=ssh, systems=[], etc.). Read from that
  # processed list so the formatter never trips on a missing field.
  processedBuilders = config.nix.buildMachines;

  # Serialise one builder to the textual format Nix's daemon expects in
  # `nix.conf`'s `builders` line. Mirrors `buildMachinesText` from
  # nixos/modules/config/nix-remote-build.nix so the result is identical
  # to what NixOS writes to /etc/nix/machines — we just inline it instead
  # of relying on `@/etc/nix/machines`, which Nix 2.34 parses but does
  # not act on (the daemon's `external-builders` list stays empty and the
  # client reports "configure remote builders via 'builders'" forever).
  formatBuilder = b:
    let
      # Nix 2.34 refuses to dispatch derivations to a builder whose protocol
      # is `ssh` (the NixOS default): the daemon leaves `external-builders`
      # empty even when the `builders` line is well-formed, and the client
      # falls back to local. `ssh-ng` (the new in-band protocol) actually
      # opens the dispatcher. Override the NixOS default here.
      proto = "ssh-ng://";
      user = if b.sshUser != null && b.sshUser != "" then "${b.sshUser}@" else "";
      systems =
        if b.system != null then b.system
        else if b.systems != [ ] then lib.concatStringsSep "," b.systems
        else "-";
      sshKey = if b.sshKey != null && b.sshKey != "" then b.sshKey else "-";
      maxJobs = toString b.maxJobs;
      speedFactor = toString b.speedFactor;
      allFeats = b.supportedFeatures ++ b.mandatoryFeatures;
      supported =
        if allFeats == [ ] then "-"
        else lib.concatStringsSep "," allFeats;
      mandatory =
        if b.mandatoryFeatures == [ ] then "-"
        else lib.concatStringsSep "," b.mandatoryFeatures;
      publicKey = if b.publicHostKey != null then b.publicHostKey else "-";
    in
    lib.concatStringsSep " " [
      "${proto}${user}${b.hostName}"
      systems
      sshKey
      maxJobs
      speedFactor
      supported
      mandatory
      publicKey
    ];
  inlineBuilders = lib.concatMapStringsSep "\n" formatBuilder processedBuilders;

  # One OpenSSH host block per builder that needs a ProxyCommand.
  # Placed in `programs.ssh.extraConfig` so it ends up in
  # /etc/ssh/ssh_config (the file OpenSSH consults system-wide, including
  # for the nix-daemon running as root).
  #
  # Only builders with a `proxyCommand` attribute get a block: a builder
  # reachable on its own (e.g. otreca on a public IP) needs no help from
  # here. The attribute is the literal ProxyCommand string (passed
  # verbatim to ssh); the configuration is responsible for matching it
  # with the `hostName` field.
  hostBlock = b: ''
    Host ${b.hostName}
      User ${b.sshUser}
      HostKeyAlias ${b.hostKeyAlias or b.hostName}
      ProxyCommand ${b.proxyCommand}
      StrictHostKeyChecking accept-new
      ServerAliveInterval 30
      ServerAliveCountMax 3
      ControlMaster auto
      ControlPersist 60
      ConnectTimeout 15
  '';
  blocks = map hostBlock (lib.filter (b: b ? proxyCommand) config.host.builder.clients);
in
{
  config = lib.mkIf (config.host.builder.clients != [ ]) {
    # Off-by-default in NixOS. Without this, the nix-remote-build module
    # sets `nix.settings.builders = null` and the list is dropped from
    # /etc/nix/nix.conf entirely, even though `nix.buildMachines` is
    # populated. (The build-machine list still lands in /etc/nix/machines
    # but nix-daemon reads `builders`, not /etc/nix/machines, when
    # distributedBuilds is false.)
    nix.distributedBuilds = true;
    nix.buildMachines = map forNix config.host.builder.clients;
    # Nix 2.34's daemon does not act on `@/etc/nix/machines` (the file
    # format NixOS's nix-remote-build writes to): the `builders` config
    # key is parsed for display but `external-builders` stays empty and
    # the scheduler ignores it. Inlining the same builder text here — in
    # the exact format the NixOS module itself uses — actually wires up
    # the SSH dispatch. `mkForce` is required because the nix-remote-build
    # module sets `builders = null` whenever distributedBuilds is *false*;
    # our config flips it to *true*, so the module's mkIf does not fire
    # and there is no actual conflict — but pinning it with mkForce makes
    # the intent obvious and survives any future change in default
    # behaviour.
    nix.settings.builders = lib.mkForce inlineBuilders;

    # Append per-builder Host blocks to the system-wide OpenSSH client
    # config. `programs.ssh.extraConfig` is of type `lines`, merged across
    # modules, and prepended (before `Host *`) in /etc/ssh/ssh_config —
    # which is exactly the spot where specific Host blocks have to live.
    programs.ssh.extraConfig = lib.concatStrings blocks;

    # Parallel builds on sapphira itself stay at 2 — that matches the
    # physical cores and keeps the coordinator responsive while the WSL
    # absorbs the heavy lifting. The essentials/settings.nix already
    # leaves max-jobs at the default `auto` (2 here); no override needed.
  };
}