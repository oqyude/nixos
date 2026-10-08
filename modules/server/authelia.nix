{
  config,
  lib,
  pkgs,
  ...
}:
# Authelia — SSO reverse-proxy (single-factor password login) for protected
# vhosts. Uses nixpkgs' services.authelia module (a native systemd unit with
# hard sandboxing) instead of a podman container — Authelia is a Go binary,
# not a foreign distro, so a container adds nothing but surface area.
#
# Wiring:
#   - The internal API listens on 127.0.0.1:9091 only (overrides the nixpkgs
#     default `tcp://:9091/` which would bind all interfaces).
#   - Three secrets (jwt, storage encryption key, users_database) come from
#     modules/server/secrets/authelia.yaml via sops-nix, materialised at
#     /run/secrets/<name> by the time authelia.service starts.
#   - nginx is the only ingress: authelia.zeroq.su vhosts the login UI and
#     every protected vhost (currently vtimeline.zeroq.su) does
#     `auth_request /authelia` against 127.0.0.1:9091 (see nginx.nix).
#   - users_database.yml is symlinked into /var/lib/authelia/ so the path
#     configured in `settings.authentication_backend.file.path` resolves
#     to the sops materialised file. The symlink target is created by
#     sops-nix before this unit starts, so no race.
#
# Version: pinned transitively via flake inputs.nixpkgs → pkgs.authelia.
# `nix flake update` will roll it forward; no overlay needed.
#
# Secrets layout in modules/server/secrets/authelia.yaml (sops-encrypted):
#   jwt_secret              -> /run/secrets/authelia-jwt-secret
#   storage_encryption_key  -> /run/secrets/authelia-storage-encryption-key
#   users_database          -> /run/secrets/authelia-users-database
#                              (multiline YAML string, written verbatim by
#                               sops-nix and consumed as a settingsFile)
#
# Guarded by `builtins.pathExists` so a missing sops file does NOT break
# `nixos-rebuild switch` — the flake evaluates, Authelia stays disabled
# until the secret file is created and encrypted.
let
  cfg = config.host.authelia;
  sopsReady = builtins.pathExists ./secrets/authelia.yaml;
  # sops-nix materialises each `sops.secrets.<attr-name>` at
  # /run/secrets/<attr-name> by default. Hardcoding the path here keeps
  # the module independent of how the secret attr is named; rename only
  # the sops block below if a different path is needed.
  sopsPath = name: "/run/secrets/${name}";
in
{
  options.host.authelia = {
    enable = lib.mkEnableOption ''
      Authelia SSO reverse-proxy. When enabled, exposes the internal API on
      127.0.0.1:9091 (loopback only — nginx is the only ingress). Activating
      this option requires modules/server/secrets/authelia.yaml to exist
      and decrypt successfully; otherwise the toplevel build fails on a
      missing sopsFile.
    '';
    cookieDomain = lib.mkOption {
      type = lib.types.str;
      default = "zeroq.su";
      description = ''
        Domain scope for Authelia session cookies and the login-UI vhost
        (`authelia.<cookieDomain>`). All protected vhosts must be subdomains
        of this value for the session cookie to flow through nginx's
        auth_request handshake.
      '';
    };
    autheliaFqdn = lib.mkOption {
      type = lib.types.str;
      default = "authelia.${cfg.cookieDomain}";
      description = ''
        Public FQDN where the Authelia login UI is served by nginx. Set this
        to override the default (authelia.<cookieDomain>) when a CNAME or a
        different deployment shape requires it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.authelia.instances."" = {
      enable = true;
      # Default is already pkgs.authelia; pinned here for clarity and to
      # give an obvious handle for future overrides (e.g. an overlay to
      # hold a specific upstream version during CVE windows).
      package = pkgs.authelia;

      secrets = lib.mkIf sopsReady {
        jwtSecretFile = sopsPath "authelia-jwt-secret";
        storageEncryptionKeyFile = sopsPath "authelia-storage-encryption-key";
      };

      settings = {
        # Override the nixpkgs default (`tcp://:9091/`) — binding all
        # interfaces would expose the API to the LAN. nginx is the only
        # allowed ingress, talking to 127.0.0.1:9091.
        server.address = "tcp://127.0.0.1:9091";
        log = {
          level = "info";
          format = "text";
        };
        authentication_backend.file = {
          # Read directly from the sops materialised file at /run/secrets/.
          # Authelia does NOT validate-config this path — it only opens it
          # when verifying a user password (lazy read). Putting the same
          # file into settingsFiles would force viper to parse it as
          # configuration, and the `users:` top-level key would fail the
          # schema check (users.* is schema-foreign).
          path = sopsPath "authelia-users-database";
          password = {
            algorithm = "argon2id";
            iterations = 3;
            salt_length = 16;
            parallelism = 4;
            memory = 65536;
          };
        };
        storage.local.path = "/var/lib/authelia/db.sqlite3";
        session = {
          expiration = "1h";
          inactivity = "5m";
          cookies = [
            {
              domain = cfg.cookieDomain;
              authelia_url = "https://${cfg.autheliaFqdn}/";
              # NOTE: Authelia 4.x has no per-cookie `secure` knob;
              # `Set-Cookie`'s Secure flag is auto-determined from the
              # inbound request's effective scheme at runtime (it does
              # trust X-Forwarded-Proto when it sees it). The HTTP
              # loopback binding (server.address = 127.0.0.1:9091)
              # means this only works because nginx sets
              # X-Forwarded-Proto $scheme, both via
              # recommendedProxySettings and explicitly on the
              # /authelia subrequest in nginx.nix. Don't be tempted
              # to re-add `secure: "always"` here — validate-config
              # rejects it as an unknown key.
            }
          ];
        };
        access_control = {
          default_policy = "deny";
          rules = [
            {
              # Wildcard against every *.zeroq.su vhost that adds an
              # `auth_request /authelia` to its nginx config (currently
              # vtimeline). A bare `domain: "*"` is schema-invalid in
              # Authelia and silently falls through to default_policy,
              # which is why the first attempt landed on 403 with no
              # redirect. Adding a new protected vhost under this domain
              # requires no change here — the wildcard does the work.
              domain = "*.${cfg.cookieDomain}";
              policy = "one_factor";
            }
          ];
        };
        notifier = {
          disable_startup_check = true;
          filesystem.filename = "/var/lib/authelia/notifier.txt";
        };
      };

      # No `settingsFiles` — the users_database file is read directly
      # via `settings.authentication_backend.file.path` above. Adding
      # it here would put `users:` under viper's config schema check
      # (validate-config), which rejects it as an unknown top-level key.
    };

    # Wait for sops-nix to materialise the secrets before Authelia starts.
    # Without this, authelia can race ahead of sops and read an empty
    # /run/secrets on the very first boot after a switch. Existing boots
    # (when /run/secrets is already populated) skip the wait instantly.
    # `sops-nix.service` is the systemd service that the sops-nix module
    # creates to deploy credentials; depending on its name avoids the
    # "race between tmpfiles-setup and the sops materialiser" that the
    # previous tmpfiles-symlink design implicitly relied on.
    systemd.services.authelia.after = [ "sops-nix.service" ];
    systemd.services.authelia.wants = [ "sops-nix.service" ];

    # sops wiring. Guarded by builtins.pathExists so the flake still
    # evaluates when ./secrets/authelia.yaml hasn't been created yet —
    # a clean checkout would otherwise fail every nixos-rebuild switch.
    # Once the file exists and is encrypted, this condition becomes true
    # and the three secrets are wired in.
    sops.secrets = lib.optionalAttrs sopsReady {
      "authelia-jwt-secret" = {
        format = "yaml";
        key = "jwt_secret";
        sopsFile = ./secrets/authelia.yaml;
        owner = "authelia";
        group = "authelia";
        mode = "0400";
      };
      "authelia-storage-encryption-key" = {
        format = "yaml";
        key = "storage_encryption_key";
        sopsFile = ./secrets/authelia.yaml;
        owner = "authelia";
        group = "authelia";
        mode = "0400";
      };
      # users_database is a multiline YAML string in the sops file
      # (top-level `users_database: |` block with `users: <name>: ...`
      # beneath). sops-nix writes the decoded block verbatim to
      # /run/secrets/authelia-users-database, where the symlink rule
      # above makes it appear at /var/lib/authelia/users_database.yml.
      "authelia-users-database" = {
        format = "yaml";
        key = "users_database";
        sopsFile = ./secrets/authelia.yaml;
        owner = "authelia";
        group = "authelia";
        mode = "0400";
      };
    };
  };
}