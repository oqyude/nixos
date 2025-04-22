{
  description = "zeroq variables";

  outputs = { self }: (import ./vars.nix) // {};
}
