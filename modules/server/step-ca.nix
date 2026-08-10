{
  config,
  inputs,
  pkgs,
  xlib,
  ...
}:
let
  sourceDir = "${xlib.dirs.services-mnt-folder}/step-ca";
  targetDir = "/var/lib/step-ca";
in
{
  services.step-ca = {
    enable = true;
    address = "0.0.0.0";
    port = 9000;
    openFirewall = true;
    intermediatePasswordFile = config.sops.secrets.intermediate-password.path;
    settings = {
      root = "${targetDir}/certs/root_ca.crt";
      crt = "${targetDir}/certs/intermediate_ca.crt";
      key = "${targetDir}/secrets/intermediate_ca_key";
      # address = "0.0.0.0:9000";
      dnsNames = [
        "*.zeroq.su"
        "*.home.arpa"
        "localhost"
      ];
      db = {
        type = "badgerv2";
        dataSource = "${targetDir}/db";
      };
      authority = {
        claims = {
          defaultTLSCertDuration = "2160h";
          maxTLSCertDuration = "2160h";
        };
        provisioners = [
          {
            type = "ACME";
            name = "acme";
            claims = {
              enableSSHCA = false;
              allowSANs = [
                "*.home.arpa"
                "*.zeroq.su"
                "home.arpa"
                "localhost"
              ];
              maxTLSCertDuration = "2160h";
            };
          }
          {
            type = "JWK";
            name = "oqyude@zeroq.su";
            key = {
              use = "sig";
              kty = "EC";
              kid = "XEpzFJA-sedFf0ANCiEH1UDaSvrHiZabLahQOyoAYmc";
              crv = "P-256";
              alg = "ES256";
              x = "AGHevH0UU7_abhE6d8JhNuNRgXBeVI7qCldZrFfkn5o";
              y = "pLKOpAwUiGRv4HRQUyiXFAMqsywTjrjazeEkDOr29Sk";
            };
            encryptedKey = "eyJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1ciLCJjdHkiOiJqd2sranNvbiIsImVuYyI6IkEyNTZHQ00iLCJwMmMiOjYwMDAwMCwicDJzIjoibFlONzBwMWJiVzc0MDlGaS1EOEZVUSJ9.zBEsf2hAaj4yyy_Lk1Jss7h5Hn68kz6UMeg3Jz3X_VVeMWLvcoRVaw.tpY50S9CSzmcfWXz.u5ta_Yd3GLMz19RKA2WondVIwTGbGs3is5v7_D0aUOtQ0158d4GcjrOHFD2PexaackbTNuUPtqa2X38ypnFq5wh1uq3udWu-qWRjRSd_YkY4YJt_GWFvUHQ_jldx0NSfMDNGndU2IakR62-9WklEjU3UGmUeaPGP9DTuzmdJa36t2aLuPuNnmV-tEJIH3eQ5huU8nLy1ROZjdkrF-agHh78EG_Ss8P4vHuqOtTAjZW3YCtfSfb57iKAsbrk3nUTo6zhPc0ds8cPB7Rva0K8Rj2Pf3apB7qZnCVF5zBiu1icvhOYIfwVQAiqpdz6qMi42QSBWZ4ROu4Db2q5a6D0.AS7Dr3v_Niiwy7aHIR-0bw";
          }
        ];
      };
    };
  };

  fileSystems."${targetDir}" = {
    device = "${sourceDir}";
    fsType = "none";
    options = [
      "bind"
      "nofail"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      step-cli
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${sourceDir} 0755 nobody nogroup -"
    "z ${sourceDir} 0755 nobody nogroup -"
    "Z ${sourceDir}/ 0700 nobody nogroup -"
  ];

  sops.secrets = {
    intermediate-password = {
      format = "yaml";
      key = "intermediate-password";
      sopsFile = ./secrets/step-ca.yaml;
      # owner = "nobody";
      # group = "nogroup";
      mode = "0600";
    };
  };
}
