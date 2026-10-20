# The tool set a Gitea Actions job on sapphira needs.
#
# Two consumers, one list, so they cannot drift apart:
#
#   * modules/server/gitea-runner.nix -- the runner's `hostPackages`. The
#     upstream NixOS module turns that list into the PATH of every host-mode
#     job (`path = coreutils ++ optionals wantsHost instance.hostPackages`),
#     so a tool that is not listed here does not exist for the job at all.
#
#   * devshells/default.nix -- the `ci` devshell. A job (or a developer) can
#     enter it and get the same tools without waiting for a nixos-rebuild,
#     which is what the workflows in oqyude/winos do:
#       nix develop /etc/nixos#ci --command bash -c 'echo $PATH'
#
# Keep the list sorted by purpose: the first group is the default set the
# runner has always had, the rest are tools a specific workflow needs.
{ pkgs }:
with pkgs; [
  bash coreutils curl gawk gitMinimal gnused nodejs wget
  nix
  python3
  cacert

  # scripts/update-manifest.sh in oqyude/winos hard-requires jq
  # ("for dep in curl jq") and calls it a dozen times.
  jq

  # scripts/update-kvrt.ps1 in oqyude/winos runs under pwsh; the runner has
  # no PowerShell otherwise, and `nix-shell -p powershell` is not a fallback
  # here: the nix registry on sapphira is empty, so -p cannot resolve nixpkgs.
  powershell
]
