{
  config,
  xlib,
  ...
}:
{
  xlib.device.username = "oqyude";

  users = {
    users = {
      main = {
        name = "${xlib.device.username}";
        isNormalUser = true;
        description = "Jor Oqyude";
        # initialPassword = "1234";
        hashedPasswordFile = config.sops.secrets.hashed_password.path; # hashed_password
        homeMode = "700";
        home = "/home/${config.users.users.main.name}";
        extraGroups = [
          "beets"
          "audio"
          "disk"
          "gamemode"
          "libvirtd"
          "networkmanager"
          "pipewire"
          "qemu-libvirtd"
          "wheel"
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
      # keyFile = "/var/lib/sops-nix/key.txt";
      # generateKey = true;
    };
    defaultSopsFile = ../secrets/default.yaml;
    secrets = {
      hashed_password = {
        key = "hashed_password";
        format = "yaml";
      };
      age_key_private = {
        format = "yaml";
        key = "age_key_private";
        path = "${config.users.users.main.home}/.config/sops/age/keys.txt";
        owner = config.users.users.main.name;
        group = config.users.users.main.group;
        mode = "0600";
      };
      ssh_key_private = {
        format = "yaml";
        # sopsFile = ../secrets/default.yaml;
        key = "ssh_key_private";

        path = "${config.users.users.main.home}/.ssh/id_ed25519";
        owner = config.users.users.main.name;
        group = config.users.users.main.group;
        mode = "0600";
      };
    };
  };
}
