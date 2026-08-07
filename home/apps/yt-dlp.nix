{
  config,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.yt-dlp-light
  ];
}
