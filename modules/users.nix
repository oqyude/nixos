{
  config,
  xlib,
  lib,
  ...
}:
let
  user = "${xlib.device.username}";
  userGroup = config.users.users."${user}".group;

  # sops secret factory: name == key by default, owner/group default to root.
  # `format` and `sopsFile` default to yaml + defaultSopsFile, matching every
  # pre-existing caller.
  mkSecret =
    {
      path,
      mode,
      key ? null,
      owner ? null,
      group ? null,
      format ? "yaml",
      sopsFile ? null,
    }:
    {
      inherit format path mode;
    }
    // lib.optionalAttrs (key != null) { inherit key; }
    // lib.optionalAttrs (owner != null) { inherit owner; }
    // lib.optionalAttrs (group != null) { inherit group; }
    // lib.optionalAttrs (sopsFile != null) { inherit sopsFile; };

  # default owner = device user
  mkUserSecret =
    args:
    mkSecret (
      args
      // {
        owner = user;
        group = userGroup;
      }
    );
in
{
  users = {
    mutableUsers = false;
    users = {
      "${user}" = {
        name = "${user}";
        isNormalUser = true;
        group = "users";
        # Pinned, not left to NixOS' nextfree logic: the ntfs3/exfat mount
        # helpers (lib/xlib/helpers.nix) bake xlib.device.uid into their mount
        # options, so normally both sides agree and NTFS/exFAT files do not
        # show up as owned by `nobody`. NixOS has no per-user `gid` option —
        # the primary group id comes from `group` above.
        #
        # sapphira is the one exception, and only until its filesystem gets
        # migrated: /var/lib/nixos/uid-map still reserves 1000 for the
        # long-removed `yuyus` and NixOS never renumbers an existing user, so
        # the live `oqyude` there is uid 1001. Without this branch a rebuild
        # would rewrite the user to 1000 while every file is still owned by
        # 1001. The cost: the exFAT mounts on sapphira still get uid=1000 from
        # xlib.device.uid, so that user cannot write to /mnt/archive or
        # /mnt/mobile until the id question is settled.
        # TODO: delete this branch once sapphira is migrated to 1000.
        uid = if xlib.device.hostname == "sapphira" then 1001 else xlib.device.uid;
        description = "Jor Oqyude";
        hashedPasswordFile = config.sops.secrets.hashed_password.path; # hashed_password
        homeMode = "700";
        home = "/home/${user}";
        # Linger keeps `user@<uid>.service` (the systemd user manager) alive
        # across logouts, so user services like opencode-web survive when no
        # SSH/login session is active. Without this the service is torn down
        # together with the user manager on the last session close.
        linger = true;
        extraGroups = [
          "audio"
          "disk"
          "gamemode"
          "networkmanager"
          "pipewire"
          "wheel"
          "libvirtd"
          "qemu-libvirtd"
        ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKduJia+unaQQdN6X5syaHvnpIutO+yZwvfiCP4qKQ/P"
        ];
      };
    };
  };

  sops = {
    age = {
      sshKeyPaths = [
        "/etc/ssh/id_ed25519"
      ];
    };
    defaultSopsFile = ../secrets/default.yaml;
    secrets = {
      hashed_password = {
        neededForUsers = true;
        format = "yaml";
        key = "hashed_password";
      };
      age_key_private = mkUserSecret {
        path = "${xlib.dirs.user-home}/.config/sops/age/keys.txt";
        mode = "0600";
      };
      # opencode web server creds + Gemini API key.
      # Decrypted as a single dotenv file (no `key`) and consumed by the
      # systemd user unit opencode-web as EnvironmentFile.
      # Source: secrets/opencode.env (encrypted, see sops/age below).
      # Path is shared with home/modules/opencode.nix via xlib.dirs so the
      # sops materialization and the systemd EnvironmentFile can never
      # silently desync.
      opencode_server = mkUserSecret {
        path = xlib.dirs.opencode-server-env;
        mode = "0600";
        format = "dotenv";
        sopsFile = ../secrets/opencode.env;
      };
      # opencode provider credentials (XDG_DATA_HOME/opencode/...).
      # Both files are read by opencode at startup to populate the providers
      # list. Mirror of ~/.local/share/opencode/ on the workstation.
      # key = "" → decrypt the WHOLE file as-is (the JSON has no top-level
      # field named after the secret; it IS the secret).
      opencode_auth = mkUserSecret {
        path = "${xlib.dirs.user-home}/.local/share/opencode/auth.json";
        mode = "0600";
        format = "json";
        sopsFile = ../secrets/opencode-auth.json;
        key = "";
      };
      opencode_account = mkUserSecret {
        path = "${xlib.dirs.user-home}/.local/share/opencode/account.json";
        mode = "0600";
        format = "json";
        sopsFile = ../secrets/opencode-account.json;
        key = "";
      };
      ssh_key_private = mkUserSecret {
        path = "${xlib.dirs.user-home}/.ssh/id_ed25519";
        mode = "0600";
      };
      ssh_key_public = mkUserSecret {
        path = "${xlib.dirs.user-home}/.ssh/id_ed25519.pub";
        mode = "0655";
      };
      ssh_key_private_root = mkSecret {
        key = "ssh_key_private";
        path = "/root/.ssh/id_ed25519";
        mode = "0600";
      };
      ssh_key_public_root = mkSecret {
        key = "ssh_key_public";
        path = "/root/.ssh/id_ed25519.pub";
        mode = "0655";
      };
      ssh_key_public_host = mkSecret {
        key = "ssh_key_public";
        path = "/etc/ssh/id_ed25519.pub";
        mode = "0655";
      };
    };
  };

  # fileSystems."/etc/ssh".neededForBoot = true;
}
