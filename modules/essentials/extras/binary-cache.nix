{
  config,
  ...
}:
{
  nix = {
    settings = {
      substituters = [
        "https://nixos-cache-proxy.cofob.dev" # https://gist.github.com/cofob/9b1fd205e6d961a45c225ae9f0af1394
      ];
    };
  };
}
