{
  config,
  pkgs,
  xlib,
  ...
}:
{
  programs.nekoray = {
    enable = true;
    tunMode.enable = true;
  };
}
