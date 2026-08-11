{
  config,
  xlib,
  lib,
  ...
}:
let
  user = "${xlib.device.username}";
  userGroup = config.users.users."${user}".group;

  # sops secret factory: name == key by default, owner/group default to root
  mkSecret =
    {
      path,
      mode,
      key ? null,
      owner ? null,
      group ? null,
    }:
    {
      format = "yaml";
      inherit path mode;
    }
    // lib.optionalAttrs (key != null) { inherit key; }
    // lib.optionalAttrs (owner != null) { inherit owner; }
    // lib.optionalAttrs (group != null) { inherit group; };

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
  xlib.device.username = "oqyude";

  users = {
    mutableUsers = false;
    users = {
      "${user}" = {
        name = "${user}";
        isNormalUser = true;
        group = "users";
        description = "Jor Oqyude";
        hashedPasswordFile = config.sops.secrets.hashed_password.path; # hashed_password
        homeMode = "700";
        home = "/home/${user}";
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
