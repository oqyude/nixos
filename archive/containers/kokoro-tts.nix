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
  #
  # runCommand rather than linkFarm: linkFarm entries are symlinks into other
  # store paths, and `podman build` only mounts the context root, so every COPY
  # fails with "copier: get: lstat ...: no such file or directory". Copying the
  # bytes in leaves the context with no symlinks that escape its root.
  source = pkgs.runCommand "kokoro-tts-source" { } ''
    mkdir -p "$out"
    cp -L ${./kokoro-tts/Dockerfile} "$out/Dockerfile"
    cp -L ${./kokoro-tts/app.py} "$out/app.py"
    cp -L ${./kokoro-tts/fetch_assets.py} "$out/fetch_assets.py"
    cp -L ${./kokoro-tts/requirements.txt} "$out/requirements.txt"
  '';

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
            # Inference is CPU-bound and already threaded inside torch. Measured
            # on a 24-logical-core host: median end-to-end latency for a 5.6 s
            # utterance was 1.203 s at 4 threads, 0.979 s at 12, 0.980 s at 16
            # and 1.87 s at 24, so the useful ceiling is the physical core count
            # and oversubscribing it roughly doubles the wait. These three must
            # stay equal to the Dockerfile ENV and the app.py default: whichever
            # of the three is set wins over the others.
            KOKORO_THREADS = "12";
            OMP_NUM_THREADS = "12";
            MKL_NUM_THREADS = "12";
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
          # Auto-start disabled: start manually with `systemctl start podman-kokoro-tts`.
          wantedBy = [ ];
        };
      };
    };
  };
}
