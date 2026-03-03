{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  stable = import inputs.nixpkgs-stable {
    system = "x86_64-linux";
  };
in
let
  # depsOverlay = import ./dependencies.nix {
  #   # ./dependencies-full.nix if broken
  #   inherit (pkgs) fetchurl fetchgit fetchhg;
  #   inherit pkgs;
  # };
  # python3 = pkgs.python3.override {
  #   packageOverrides = depsOverlay;
  # };
  beetsEnv = stable.python313.withPackages (ps: [
    ps.beautifulsoup4
    ps.beetcamp
    ps.beets
    ps.certifi
    ps.charset-normalizer
    ps.colorama
    ps.confuse
    ps.discogs-client
    ps.exceptiongroup
    ps.filetype
    ps.h11
    ps.httpcore
    ps.httpx
    ps.idna
    ps.jellyfish
    ps.langdetect
    ps.mediafile
    ps.munkres
    ps.musicbrainzngs
    ps.mutagen
    ps.oauthlib
    ps.packaging
    ps.pillow
    ps.platformdirs
    ps.pycountry
    ps.pylast
    ps.python-dateutil
    ps.pyyaml
    ps.requests
    ps.six
    ps.sniffio
    ps.soupsieve
    ps.typing-extensions
    ps.unidecode
    ps.urllib3
  ]);
in
{
  # nixpkgs.overlays = [
  #   (self: super: {
  #     myBeets = super.buildEnv {
  #       name = "myBeets";
  #       paths = [
  #         (super.python313.withPackages (ps: with ps; [
  #           ps.beautifulsoup4
  #           ps.beetcamp
  #           ps.beets
  #           ps.certifi
  #           ps.charset-normalizer
  #           ps.colorama
  #           ps.confuse
  #           ps.discogs-client
  #           ps.exceptiongroup
  #           ps.filetype
  #           ps.h11
  #           ps.httpcore
  #           ps.httpx
  #           ps.idna
  #           ps.jellyfish
  #           ps.langdetect
  #           ps.mediafile
  #           ps.munkres
  #           ps.musicbrainzngs
  #           ps.mutagen
  #           ps.oauthlib
  #           ps.packaging
  #           ps.pillow
  #           ps.platformdirs
  #           ps.pycountry
  #           ps.pylast
  #           ps.python-dateutil
  #           ps.pyyaml
  #           ps.requests
  #           ps.six
  #           ps.sniffio
  #           ps.soupsieve
  #           ps.typing-extensions
  #           ps.unidecode
  #           ps.urllib3
  #         ]))
  #       ];
  #       pathsToLink = [ "bin" ];
  #     };

  #     # myBeets = super.python313.withPackages (ps: with ps; [
  #     #   ps.beautifulsoup4
  #     #   ps.beetcamp
  #     #   ps.beets
  #     #   ps.certifi
  #     #   ps.charset-normalizer
  #     #   ps.colorama
  #     #   ps.confuse
  #     #   ps.discogs-client
  #     #   ps.exceptiongroup
  #     #   ps.filetype
  #     #   ps.h11
  #     #   ps.httpcore
  #     #   ps.httpx
  #     #   ps.idna
  #     #   ps.jellyfish
  #     #   ps.langdetect
  #     #   ps.mediafile
  #     #   ps.munkres
  #     #   ps.musicbrainzngs
  #     #   ps.mutagen
  #     #   ps.oauthlib
  #     #   ps.packaging
  #     #   ps.pillow
  #     #   ps.platformdirs
  #     #   ps.pycountry
  #     #   ps.pylast
  #     #   ps.python-dateutil
  #     #   ps.pyyaml
  #     #   ps.requests
  #     #   ps.six
  #     #   ps.sniffio
  #     #   ps.soupsieve
  #     #   ps.typing-extensions
  #     #   ps.unidecode
  #     #   ps.urllib3
  #     # ]);
  #   })
  # ];

  users = {
    users = {
      "${xlib.device.username}" = {
        packages = [
          beetsEnv
          pkgs.mp3gain
          pkgs.imagemagick
          #ffmpeg
        ];
      };
    };
  };
  fileSystems."/mnt/beets/music" = {
    device = "/home/${xlib.device.username}/Music"; # "${xlib.dirs.vetymae-drive}/Users/User/Music"
    options = [
      "bind"
      "uid=1000"
      "gid=1000"
      "fmask=0077"
      "dmask=0077"
      "nofail"
      #"x-systemd.device-timeout=0"
    ];
  };

  systemd.tmpfiles.rules = [
    "z /mnt/beets 0700 ${xlib.device.username} users -" # beets absolute paths
  ];
}
