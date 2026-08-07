# termux-api — C binary + scripts that talk to the Termux:API Android app.
#
# The Android app (com.termux.api, installed separately from F-Droid) is the
# actual backend: `termux-api-broadcast` sends an `am broadcast` intent to
# com.termux.api/.TermuxApiReceiver and pipes stdout/stdin over abstract unix
# sockets. The nix side only provides the CLI entry points:
#   termux-battery-status, termux-notification, termux-clipboard-*,
#   termux-toast, termux-share, termux-dialog, ...
#
# Adaptations for nix-on-droid (upstream assumes termux's /data prefix):
#   - `am` is resolved from PATH (provided by android-integration.am)
#   - scripts' shebang rewritten from the substituted `#!$out/bin/sh`
#   - termux-callback referenced by absolute store path
{
  stdenv,
  fetchFromGitHub,
  cmake,
  runtimeShell,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "termux-api";
  version = "0.59.1";

  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-api-package";
    rev = "v${version}";
    sha256 = "1pkdjxll9x9arrifppl7y37dmni5fi4jng2wfx0dgbgriyjrhxl7";
  };

  nativeBuildInputs = [ cmake ];

  # termux-api.c hardcodes PREFIX for `am` and `termux-callback`. On
  # nix-on-droid `am` comes from android-integration.am (termux-am) via PATH;
  # termux-callback lives in our own libexec dir.
  patchPhase = ''
    substituteInPlace termux-api.c \
      --replace 'execv(PREFIX "/bin/am", child_argv);' 'execvp("am", child_argv);' \
      --replace 'execl(PREFIX "/libexec/termux-callback", "termux-callback", NULL);' 'execl("${placeholder "out"}/libexec/termux-callback", "termux-callback", NULL);' \
      --replace 'execl(PREFIX "/libexec/termux-callback", "termux-callback", fds, NULL);' 'execl("${placeholder "out"}/libexec/termux-callback", "termux-callback", fds, NULL);'
  '';

  # CMake substitutes @TERMUX_PREFIX@ (= CMAKE_INSTALL_PREFIX = $out) into the
  # scripts' shebang, producing `#!$out/bin/sh` which does not exist. Rewrite
  # all shebangs to the nix runtime shell.
  postInstall = ''
    for f in $out/bin/termux-* $out/libexec/termux-callback; do
      sed -i "1s|^#!.*|#!${runtimeShell}|" "$f"
    done
  '';

  meta = {
    description = "Termux API-RPC and companion package to launch API commands";
    homepage = "https://github.com/termux/termux-api-package";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
