{
  config,
  xlib,
  lib,
  pkgs,
  ...
}:
{
  # imports = [
  #   ./others
  # ];

  xlib.device.username = "oqyude";

  users = {
    users = {
      "${xlib.device.username}" = {
        name = "${xlib.device.username}";
        isNormalUser = true;
        group = "users";
        description = "Jor Oqyude";
        hashedPasswordFile = config.sops.secrets.hashed_password.path; # hashed_password
        homeMode = "700";
        home = "/home/${xlib.device.username}";
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
        key = "hashed_password";
        format = "yaml";
      };
      age_key_private = {
        format = "yaml";
        key = "age_key_private";
        path = "/home/${xlib.device.username}/.config/sops/age/keys.txt";
        owner = config.users.users."${xlib.device.username}".name;
        group = config.users.users."${xlib.device.username}".group;
        mode = "0600";
      };
      ssh_key_private = {
        format = "yaml";
        key = "ssh_key_private";
        path = "/home/${xlib.device.username}/.ssh/id_ed25519";
        owner = config.users.users."${xlib.device.username}".name;
        group = config.users.users."${xlib.device.username}".group;
        mode = "0600";
      };
      ssh_key_public = {
        format = "yaml";
        key = "ssh_key_public";

        path = "/home/${xlib.device.username}/.ssh/id_ed25519.pub";
        owner = config.users.users."${xlib.device.username}".name;
        group = config.users.users."${xlib.device.username}".group;
        mode = "0655";
      };
      ssh_key_public_host = {
        format = "yaml";
        key = "ssh_key_public";
        path = "/etc/ssh/id_ed25519.pub";
        mode = "0655";
      };
    };
  };

  # systemd.services.nixos-auto-rebuild-sops = {
  #   description = "Auto rebuild NixOS at boot";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network-online.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "${xlib.device.username}";
  #     Group = "users";
  #     WorkingDirectory = "/etc/nixos";
  #     ExecStart = [ "/run/wrappers/bin/sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch" ];
  #   };
  # };

  # fileSystems."/etc/ssh".neededForBoot = true;
}
