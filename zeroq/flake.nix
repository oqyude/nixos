{
  description = "zeroq structure flake";

  outputs = { self }: (import ./vars.nix) // {

    zapret-dir = builtins.path { path = ./zapret; name = "zapret"; };

  };
}
