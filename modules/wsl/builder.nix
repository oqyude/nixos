# WSL NixOS — advertise this host as a remote Nix builder.
#
# Why a dedicated module instead of inlining into configurations/wsl.nix:
# every "what makes this WSL different from a desktop/server" concern
# belongs under modules/wsl/ — that is the contract the device-type import in
# modules/default.nix wires up. Keeping it here means flipping the feature on
# later on another WSL host (e.g. a future vetymae-2) is one import away.
#
# The `host.builder.enable` option itself is declared in
# modules/options.nix (cross-module).
{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.host.builder.enable {
    # WSL2 does not expose /dev/kvm to the guest (no nested virt by default,
    # and Hyper-V's /dev/kvm is not bind-mounted into the WSL namespace).
    # The default NixOS module advertises `kvm nixos-test benchmark
    # big-parallel` as this host's system-features, which is a lie: any
    # derivation that requires `kvm` will be dispatched here and immediately
    # fail with "cannot open /dev/kvm". Nix selects builders by matching the
    # derivation's required features against what the builder advertises, so
    # the only way to keep WSL useful is to retract the features it cannot
    # actually deliver. `nixos-test` is dropped for the same reason — it
    # wants kvm anyway.
    #
    # `mkForce` because the NixOS module base-config sets a non-empty
    # default; without force the lists would concatenate and the WSL would
    # *still* advertise kvm.
    nix.settings.system-features = lib.mkForce [
      "benchmark"
      "big-parallel"
    ];

    # Builds arrive over SSH as the user `oqyude` (see
    # modules/server/builder.nix). On the default trusted-users = ["root"]
    # only root can call nix-store, so the SSH session would fail to realise
    # any .drv. Adding the SSH user to trusted-users lets the remote nix-build
    # driver drive nix-store on the builder side. `mkForce` for the same
    # concatenation reason as above.
    nix.settings.trusted-users = lib.mkForce [
      "root"
      "oqyude"
    ];

    # The local daemon already parallelises across all 24 logical cores
    # (max-jobs = 24 is what we measured). When acting as a builder, we
    # want to keep that — remote builds land through SSH and the daemon
    # serves them on top of its normal pool. No override needed; documented
    # here so a future reader does not "tidy up" by setting max-jobs low.
  };
}
