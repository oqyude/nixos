{
  config,
  pkgs,
  ...
}:
{
  programs = {
    btop.enable = true;
    broot.enable = true;
    bottom.enable = true;
    fastfetch.enable = true;
  };
}
