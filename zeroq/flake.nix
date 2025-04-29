{
  description = "zeroq structure flake";

  outputs = { self }: (import ./vars.nix) // {};
}
