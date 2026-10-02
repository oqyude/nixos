{
  lib,
  pkgs,
  ...
}:

let
  # The image is built here rather than pulled: zaakirio/kokoro-ru is a
  # Hugging Face repo, not a published OCI image, and its Russian G2P has to be
  # driven through the repo's own ru_g2p.py.
  #
  # The build context goes through the store so the image is pinned to the
  # config revision: edit a file, `nixos-rebuild`, and the unit below rebuilds
  # and restarts. Reading the context off a checkout at runtime would leave the
  # running container untraceable back to any config.
  source = pkgs.linkFarm "kokoro-tts-source" [
    {
      name = "Dockerfile";
      path = toString ./kokoro-tts/Dockerfile;
    }
    {
      name = "app.py";
      path = toString ./kokoro-tts/app.py;
    }
    {
      name = "fetch_assets.py";
      path = toString ./kokoro-tts/fetch_assets.py;
    }
    {
      name = "requirements.txt";
      path = toString ./kokoro-tts/requirements.txt;
    }
  ];

  image = "localhost/kokoro-tts:latest";

  # Unchanged from the silero module, so whatever already points at
  # http://127.0.0.1:9898/v1 keeps working without edits.
  hostPort = 9898;
  containerPort = 8000;
in
{
  config = {
    virtualisation = {
      podman = {
        enable = true;

        autoPrune = {
          enable = true;
          flags = [ "--all" ];
        };

        dockerCompat = true;
      };

      oci-containers = {
        backend = "podman";

        containers.kokoro-tts = {
          image = image;

          ports = [
            "127.0.0.1:${toString hostPort}:${toString containerPort}"
          ];

          environment = {
            # Inference is CPU-bound and already threaded inside torch; these
            # keep it from oversubscribing a small machine.
            KOKORO_THREADS = "4";
            OMP_NUM_THREADS = "4";
            MKL_NUM_THREADS = "4";
            TZ = "Europe/Moscow";
          };

          # No volumes: the checkpoints, the acute-aware espeak data and
          # ruaccent's ONNX models are all baked into the image, so the
          # container needs neither a host directory nor the network to start.
          log-driver = "journald";
        };
      };
    };

    systemd = {
      services = {
        # Runs before the container. BuildKit caches the expensive layers, so
        # on every boot after the first this is a no-op that still verifies the
        # image exists.
        "podman-build-kokoro-tts" = {
          path = [ pkgs.podman ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # First build pulls torch wheels plus ~700 MB of weights.
            TimeoutSec = 3600;
          };

          script = ''
            podman build -t ${image} ${source}
          '';

          wantedBy = [ "multi-user.target" ];
        };

        "podman-kokoro-tts" = {
          # The image does not exist until the build above ran, and a `latest`
          # tag must be re-pulled on rebuild, so ordering has to be explicit.
          after = [ "podman-build-kokoro-tts.service" ];
          requires = [ "podman-build-kokoro-tts.service" ];
          serviceConfig.Restart = lib.mkOverride 90 "always";
          wantedBy = [ "multi-user.target" ];
        };
      };
    };
  };
}