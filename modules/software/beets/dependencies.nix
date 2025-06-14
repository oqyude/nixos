# Generated by pip2nix 0.8.0.dev1
# See https://github.com/nix-community/pip2nix

{
  pkgs,
  fetchurl,
  fetchgit,
  fetchhg,
}:

self: super: {
  "PyYAML" = super.buildPythonPackage rec {
    pname = "PyYAML";
    version = "6.0.2";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/54/ed/79a089b6be93607fa5cdaedf301d7dfb23af5f25c398d5ead2525b063e17/pyyaml-6.0.2.tar.gz";
      sha256 = "0gmwggzm0j0iprx074g5hah91y2f68sfhhldq0f8crddj7ndk16m";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "Unidecode" = super.buildPythonPackage rec {
    pname = "Unidecode";
    version = "1.3.8";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/84/b7/6ec57841fb67c98f52fc8e4a2d96df60059637cba077edc569a302a8ffc7/Unidecode-1.3.8-py3-none-any.whl";
      sha256 = "0fgxj6h9lkjq4saynkjqf2wb9plsr5wyg3xxld482vv9wqfacc6i";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "anyio" = super.buildPythonPackage rec {
    pname = "anyio";
    version = "4.7.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/a0/7a/4daaf3b6c08ad7ceffea4634ec206faeff697526421c20f07628c7372156/anyio-4.7.0-py3-none-any.whl";
      sha256 = "0lp30wfn1hs2wvaz3wadzwwcb3l9ii4b1k78yzzscaxl79rc6q7a";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."exceptiongroup"
      self."idna"
      self."sniffio"
      self."typing-extensions"
    ];
  };
  "beautifulsoup4" = super.buildPythonPackage rec {
    pname = "beautifulsoup4";
    version = "4.12.3";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b1/fe/e8c672695b37eecc5cbf43e1d0638d88d66ba3a44c4d321c796f4e59167f/beautifulsoup4-4.12.3-py3-none-any.whl";
      sha256 = "1vc2w3wvnhbp2q287ilzjsiqyvd0vc5s52ysalz32481yk4ph25q";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."soupsieve"
    ];
  };
  "beetcamp" = super.buildPythonPackage rec {
    pname = "beetcamp";
    version = "0.21.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/6c/d3/94cad1ba1e65a9445655968a6dcdd528cb1352e2389f0921a9f8c0ccd4a0/beetcamp-0.21.0-py3-none-any.whl";
      sha256 = "08mxqmckg2fx9rkm5a1n9zs2sjccjj75vgxac22xjyi3fw1k0wz2";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      #self."beets" # its doesnt matter?
      self."httpx"
      self."packaging"
      self."pycountry"
    ];
  };
  "beets" = super.buildPythonPackage rec {
    pname = "beets";
    version = "2.2.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/f3/44/1c53c2ac111e5526083e58f50a22504ad7c609be1ce660c0339938a42c33/beets-2.2.0-py3-none-any.whl";
      sha256 = "076hl1j74cgyh6n1piwprnzb89gihy2vmajm8lzfhy1jjcrfrpbd";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."PyYAML"
      self."Unidecode"
      self."confuse"
      self."jellyfish"
      self."mediafile"
      self."munkres"
      self."musicbrainzngs"
      self."platformdirs"
      self."typing-extensions"
      # ext
      self."requests" # For spotify, deezer, embedart, fetchart, lyrics
      self."python3-discogs-client" # For discogs
      self."pylast" # For lastgenre
      self."beetcamp" # Another
    ];
  };
  "certifi" = super.buildPythonPackage rec {
    pname = "certifi";
    version = "2024.12.14";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/a5/32/8f6669fc4798494966bf446c8c4a162e0b5d893dff088afddf76414f70e1/certifi-2024.12.14-py3-none-any.whl";
      sha256 = "0mpccx4yscnk6rhl12fk8wpgwrpq62m4w23k27y4wip9bfjgfx8j";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "charset-normalizer" = super.buildPythonPackage rec {
    pname = "charset-normalizer";
    version = "3.4.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/16/b0/572805e227f01586461c80e0fd25d65a2115599cc9dad142fee4b747c357/charset_normalizer-3.4.1.tar.gz";
      sha256 = "18sfsqpdmxbddr3g3yg0sln10ghq4sp0vl2xb1b5p9v8rlc1y9a4";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "colorama" = super.buildPythonPackage rec {
    pname = "colorama";
    version = "0.4.6";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/d1/d6/3965ed04c63042e047cb6a3e6ed1a63a35087b6a609aa3a15ed8ac56c221/colorama-0.4.6-py2.py3-none-any.whl";
      sha256 = "1ijz53xpmxds2qf02l9yf0rnp7bznwh3ci4xkw8wmh5cyn8rj7ag";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "confuse" = super.buildPythonPackage rec {
    pname = "confuse";
    version = "2.0.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/32/1f/cf496479814d41fc252004482deeb90b740b4a6a391a3355c0b11d7e0abf/confuse-2.0.1-py3-none-any.whl";
      sha256 = "0amxm8vnxcayh7inahvj3fzj33n8gs8lvcfaicqrpjz2f2y5p7lv";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."PyYAML"
    ];
  };
  "exceptiongroup" = super.buildPythonPackage rec {
    pname = "exceptiongroup";
    version = "1.3.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/36/f4/c6e662dade71f56cd2f3735141b265c3c79293c109549c1e6933b0651ffc/exceptiongroup-1.3.0-py3-none-any.whl";
      sha256 = "044alxyhkfdlr5z3xlpnf5lv78310bnsgnkdmm669l0k1ip1w4ad";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."typing-extensions"
    ];
  };
  "filetype" = super.buildPythonPackage rec {
    pname = "filetype";
    version = "1.2.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/18/79/1b8fa1bb3568781e84c9200f951c735f3f157429f44be0495da55894d620/filetype-1.2.0-py2.py3-none-any.whl";
      sha256 = "099d3igvmfcdgg9dcylz8advva5n3qpplsf8gb7l24hqh1l1prvw";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "h11" = super.buildPythonPackage rec {
    pname = "h11";
    version = "0.14.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/95/04/ff642e65ad6b90db43e668d70ffb6736436c7ce41fcc549f4e9472234127/h11-0.14.0-py3-none-any.whl";
      sha256 = "0qd7z9p38dwx215048q708vd1sn2abdh1mb3hg66ii2ip324mzp3";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "httpcore" = super.buildPythonPackage rec {
    pname = "httpcore";
    version = "1.0.7";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/87/f5/72347bc88306acb359581ac4d52f23c0ef445b57157adedb9aee0cd689d2/httpcore-1.0.7-py3-none-any.whl";
      sha256 = "1p8f8bnrir1d50s6z19jndca98qghgqrr7rx6syxaq627psgizx3";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."certifi"
      self."h11"
    ];
  };
  "httpx" = super.buildPythonPackage rec {
    pname = "httpx";
    version = "0.28.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/2a/39/e50c7c3a983047577ee07d2a9e53faf5a69493943ec3f6a384bdc792deb2/httpx-0.28.1-py3-none-any.whl";
      sha256 = "1barpaw8as8xb7b2bsmzdmdbq5nqljlq5jhlz3xcgy0hq76gq2fr";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."anyio"
      self."certifi"
      self."httpcore"
      self."idna"
    ];
  };
  "idna" = super.buildPythonPackage rec {
    pname = "idna";
    version = "3.10";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/76/c6/c88e154df9c4e1a2a66ccf0005a88dfb2650c1dffb6f5ce603dfbd452ce3/idna-3.10-py3-none-any.whl";
      sha256 = "1lw72a5swas501zvkpd6dsryj5hzjijqxs3526kbp7151md1jvcl";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  #   "jellyfish" = super.buildPythonPackage rec { # That is Rust package
  #     pname = "jellyfish";
  #     version = "1.1.3";
  #     src = fetchurl {
  #       url = "https://files.pythonhosted.org/packages/5b/3a/f607d7d44ee5cbad51ce8e2966bde112789eeb53633558f500bc4e44c053/jellyfish-1.1.3.tar.gz";
  #       sha256 = "17wgy021wsp8jj95v638kfk34r9yzbry3q7shnglj5npmgfs22v5";
  #     };
  #     format = "setuptools";
  #     doCheck = false;
  #     buildInputs = [ ];
  #     checkInputs = [ ];
  #     nativeBuildInputs = [ ];
  #     propagatedBuildInputs = [ ];
  #   };
  "langdetect" = super.buildPythonPackage rec {
    pname = "langdetect";
    version = "1.0.9";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/0e/72/a3add0e4eec4eb9e2569554f7c70f4a3c27712f40e3284d483e88094cc0e/langdetect-1.0.9.tar.gz";
      sha256 = "1805svvb7xjm4sf1j7b6nc3409x37pd1xmabfwwjf1ldkzwgxhfb";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."six"
    ];
  };
  "mediafile" = super.buildPythonPackage rec {
    pname = "mediafile";
    version = "0.13.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/9f/b0/363b4d1443a593398f9d3784f406385f075e8fd0991c35356e73fc37638a/mediafile-0.13.0-py3-none-any.whl";
      sha256 = "1jqlwmwpgn0fxkbxrj8y5a4wr3ikwgs2rsc678hbaw861qyii3fd";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."filetype"
      self."mutagen"
    ];
  };
  "munkres" = super.buildPythonPackage rec {
    pname = "munkres";
    version = "1.1.4";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/90/ab/0301c945a704218bc9435f0e3c88884f6b19ef234d8899fb47ce1ccfd0c9/munkres-1.1.4-py2.py3-none-any.whl";
      sha256 = "0apdpkbhg4wq5pis5d2mkqg46ikwix5nwcm2mrjxi04499yqc0bb";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "musicbrainzngs" = super.buildPythonPackage rec {
    pname = "musicbrainzngs";
    version = "0.7.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/6d/fd/cef7b2580436910ccd2f8d3deec0f3c81743e15c0eb5b97dde3fbf33c0c8/musicbrainzngs-0.7.1-py2.py3-none-any.whl";
      sha256 = "040s1q4ia6gl2bjjxrjs384980854s9za28b55r0lk0hfpwshhg8";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "mutagen" = super.buildPythonPackage rec {
    pname = "mutagen";
    version = "1.47.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b0/7a/620f945b96be1f6ee357d211d5bf74ab1b7fe72a9f1525aafbfe3aee6875/mutagen-1.47.0-py3-none-any.whl";
      sha256 = "06d7miq4z6m7j8rx2czkmqhgbjb2bwjagfz5v0wraylhqm86zngd";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "oauthlib" = super.buildPythonPackage rec {
    pname = "oauthlib";
    version = "3.2.2";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/7e/80/cab10959dc1faead58dc8384a781dfbf93cb4d33d50988f7a69f1b7c9bbe/oauthlib-3.2.2-py3-none-any.whl";
      sha256 = "1jpvcxq0xr3z50fdg828in1icgz8cfcy3sc04r85vqhkmjdg4fc1";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "packaging" = super.buildPythonPackage rec {
    pname = "packaging";
    version = "24.2";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/88/ef/eb23f262cca3c0c4eb7ab1933c3b1f03d021f2c48f54763065b6f0e321be/packaging-24.2-py3-none-any.whl";
      sha256 = "0nd7a421brjgd4prm8fbs8a6bcv4n1yplgxalgs02p16rnyb3aq9";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "pillow" = super.buildPythonPackage rec {
    pname = "pillow";
    version = "11.0.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/a5/26/0d95c04c868f6bdb0c447e3ee2de5564411845e36a858cfd63766bc7b563/pillow-11.0.0.tar.gz";
      sha256 = "0fbpcwgiac19ap0h1qa1imsqhq6vxv8kg67zkgm3y05c4jpwpfkj";
    };
    format = "setuptools";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "platformdirs" = super.buildPythonPackage rec {
    pname = "platformdirs";
    version = "4.3.6";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/3c/a6/bc1012356d8ece4d66dd75c4b9fc6c1f6650ddd5991e421177d9f8f671be/platformdirs-4.3.6-py3-none-any.whl";
      sha256 = "1yy39iay8fdb3c1r4gm011lla1sk1mc9fsw300wi1f4a83hpbrbk";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "pycountry" = super.buildPythonPackage rec {
    pname = "pycountry";
    version = "24.6.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b1/ec/1fb891d8a2660716aadb2143235481d15ed1cbfe3ad669194690b0604492/pycountry-24.6.1-py3-none-any.whl";
      sha256 = "0vz0dhfkbjld5jagh9wafwy27k5d83bmd5fkxy74y8fp3hwzp97i";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "pylast" = super.buildPythonPackage rec {
    pname = "pylast";
    version = "5.3.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/9b/57/e25206d012afe3fe5e3336a875babb5413b81c00706411a645a38185ad3b/pylast-5.3.0-py3-none-any.whl";
      sha256 = "023ki92jgc9mk2k9c4li48zf23yz2wn022m1rsjj9bsvn3f7ri2c";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."httpx"
    ];
  };
  "python-dateutil" = super.buildPythonPackage rec {
    pname = "python-dateutil";
    version = "2.9.0.post0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/ec/57/56b9bcc3c9c6a792fcbaf139543cee77261f3651ca9da0c93f5c1221264b/python_dateutil-2.9.0.post0-py2.py3-none-any.whl";
      sha256 = "09q48zvsbagfa3w87zkd2c5xl54wmb9rf2hlr20j4a5fzxxvrcm8";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."six"
    ];
  };
  "python3-discogs-client" = super.buildPythonPackage rec {
    pname = "python3-discogs-client";
    version = "2.7.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/02/eb/b3d321440728addb72296e75ae2bfddd8fd3518b5ce5bd54a1ad821227a2/python3_discogs_client-2.7.1-py3-none-any.whl";
      sha256 = "0i3lfdn2ncxfvmmldg31gmdv7vdcicjl890mihncxa48yb9g7daz";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."oauthlib"
      self."python-dateutil"
      self."requests"
    ];
  };
  "requests" = super.buildPythonPackage rec {
    pname = "requests";
    version = "2.32.3";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/f9/9b/335f9764261e915ed497fcdeb11df5dfd6f7bf257d4a6a2a686d80da4d54/requests-2.32.3-py3-none-any.whl";
      sha256 = "1inwsrhx0m16q0wa1z6dfm8i8xkrfns73xm25arcwwy70gz1qxkh";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [
      self."certifi"
      self."charset-normalizer"
      self."idna"
      self."urllib3"
    ];
  };
  "six" = super.buildPythonPackage rec {
    pname = "six";
    version = "1.17.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b7/ce/149a00dd41f10bc29e5921b496af8b574d8413afcd5e30dfa0ed46c2cc5e/six-1.17.0-py2.py3-none-any.whl";
      sha256 = "0x1jdic712dylbnyiqdj4xyxrlx0gaacynmbmkfiym4hxn8z68a7";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "sniffio" = super.buildPythonPackage rec {
    pname = "sniffio";
    version = "1.3.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/e9/44/75a9c9421471a6c4805dbf2356f7c181a29c1879239abab1ea2cc8f38b40/sniffio-1.3.1-py3-none-any.whl";
      sha256 = "18i50l85yppn9w1ily8m342yd577h0bg8y24hkfzvq7is4ca8v9g";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "soupsieve" = super.buildPythonPackage rec {
    pname = "soupsieve";
    version = "2.6";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/d1/c2/fe97d779f3ef3b15f05c94a2f1e3d21732574ed441687474db9d342a7315/soupsieve-2.6-py3-none-any.whl";
      sha256 = "1jfc0b39kwnh4n30458mr8gmh50mx3k5zxghm6sy9djgdvq4yb77";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "typing-extensions" = super.buildPythonPackage rec {
    pname = "typing-extensions";
    version = "4.12.2";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/26/9f/ad63fc0248c5379346306f8668cda6e2e2e9c95e01216d2b8ffd9ff037d0/typing_extensions-4.12.2-py3-none-any.whl";
      sha256 = "03bhjivpvdhn4c3x0963z89hv7b5vxr415akd1fgiwz0a41wmr84";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
  "urllib3" = super.buildPythonPackage rec {
    pname = "urllib3";
    version = "2.3.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/c8/19/4ec628951a74043532ca2cf5d97b7b14863931476d117c471e8e2b1eb39f/urllib3-2.3.0-py3-none-any.whl";
      sha256 = "1pz380a93mhdrzx5003inw5pm5n0fh1xazcbnjxzsyw6d79rmvhw";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [ ];
    checkInputs = [ ];
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
  };
}
