{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
# let
#   depsOverlay = import ./dependencies.nix {
#     # ./dependencies-full.nix if broken
#     inherit (pkgs) fetchurl fetchgit fetchhg;
#     inherit pkgs;
#   };
#   python3 = pkgs.python3.override {
#     packageOverrides = depsOverlay;
#   };
#   beetsEnv = python3.withPackages (ps: [
#     ps.beets
#   ]);
# in
{
  systemd.tmpfiles.rules = [
    "z /mnt/beets 0700 ${xlib.device.username} users -" # beets absolute paths
  ];

  users = {
    users = {
      "${xlib.device.username}" = {
        packages = [
          python313Packages.anyio
          python313Packages.beautifulsoup4
          python313Packages.beetcamp
          python313Packages.beets
          python313Packages.certifi
          python313Packages.discogs-client
          python313Packages.pyyaml
          python313Packages.unidecode
          python313Packages.charset-normalizer
          python313Packages.colorama
          python313Packages.confuse
          python313Packages.exceptiongroup
          python313Packages.filetype
          python313Packages.h11
          python313Packages.httpcore
          python313Packages.httpx
          python313Packages.idna
          python313Packages.jellyfish
          python313Packages.langdetect
          python313Packages.mediafile
          python313Packages.munkres
          python313Packages.musicbrainzngs
          python313Packages.mutagen
          python313Packages.oauthlib
          python313Packages.packaging
          python313Packages.pillow
          python313Packages.platformdirs
          python313Packages.pycountry
          python313Packages.pylast
          python313Packages.python-dateutil
          python313Packages.requests
          python313Packages.six
          python313Packages.sniffio
          python313Packages.soupsieve
          python313Packages.typing-extensions
          python313Packages.urllib3
          # beetsEnv
          pkgs.mp3gain
          pkgs.imagemagick
          #pkgs.ffmpeg
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
}
