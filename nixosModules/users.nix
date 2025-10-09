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
        initialPassword = "1234";
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
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = false;
    };
    defaultSopsFile = ../secrets/default.yaml; # наш зашифрованный файл
    # Указываем секрет SSH-ключа:
    secrets = {
      age_key = {
        format = "yaml";
        sopsFile = ../secrets/age.yaml;
        key = "age_key";

        path = "${config.users.users.main.home}/.config/sops/age/keys.txt";
        owner = config.users.users.main.name; # владелец – наш пользователь
        group = config.users.users.main.group; # группа пользователя
        mode = "0600";
      };
      ssh_key = {
        # формат секрета (YAML по умолчанию)
        format = "yaml";
        sopsFile = ../secrets/default.yaml;
        # (имя ключа в YAML: "ssh_key", т.е. ключ из файла выше)
        key = "ssh_key";

        path = "${config.users.users.main.home}/.ssh/id_ed25519";
        owner = config.users.users.main.name; # владелец – наш пользователь
        group = config.users.users.main.group; # группа пользователя
        mode = "0600"; # права 600
      };
    };
  };
}
