{ pkgs }:

let
  python = pkgs.python314.override {
    packageOverrides = self: super: {
      textual = super.textual.overridePythonAttrs (old: rec {
        version = "7.1.0";
        src = super.fetchPypi {
          pname = "textual";
          inherit version;
          sha256 = "sha256-PHFI7wCpJ3tF/Xihpq3HxBnEUdPtcUoLAVsW6qKopzs=";
        };
      });
    };
  };

  py = python.pkgs;

  textualDeps = with py; [
    textual
    textual-autocomplete
    textual-image
    textual-speedups
  ];

  pythonDeps = with py; [
    ujson
    prompt-toolkit
    rich
    fastjsonschema
    humanize
    natsort
    pathvalidate
    pdf2image
    pillow
    platformdirs
    psutil
    puremagic
    rarfile
    rich-click
    send2trash
    tomli
  ];

in

py.buildPythonApplication rec {
  pname = "rovr";
  version = "0.7.0";

  src = py.fetchPypi {
    inherit pname version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    abi = "none";
    platform = "any";
    sha256 = "sha256-CMj3jepLSA2bMcl2r89HY/ghPXEIpF5RohkBkLj6iNw=";
  };

  format = "wheel";

  propagatedBuildInputs = pythonDeps ++ textualDeps;

  nativeBuildInputs = [ pkgs.stdenv.cc.cc.lib ];

  doCheck = false;

  meta = with pkgs.lib; {
    description = "Terminal file manager rovr";
    homepage = "https://pypi.org/project/rovr/";
    license = licenses.mit;
  };
}
