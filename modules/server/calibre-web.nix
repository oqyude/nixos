{
  config,
  xlib,
  inputs,
  ...
}:
let
  # work = import (builtins.fetchGit {
  #     # Descriptive name to make the store path easier to identify
  #     name = "my-old-revision";
  #     url = "https://github.com/NixOS/nixpkgs/";
  #     ref = "refs/heads/nixpkgs-unstable";
  #     rev = "e6f23dc08d3624daab7094b701aa3954923c6bbb";
  # }) {};
  # myPkg = work.calibre-web;
  work = import inputs.nixpkgs-calibre { system = "x86_64-linux"; };
in
{
  # services.calibre-server.package = stable.calibre;
  services.calibre-web = {
    enable = true;
    package = work.calibre-web;
    group = "users";
    user = "${xlib.device.username}";
    options = {
      calibreLibrary = "${xlib.dirs.calibre-library}";
      enableBookUploading = true;
      enableKepubify = true;
      enableBookConversion = false;
    };
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    openFirewall = true;
  };
}
