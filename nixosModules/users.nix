{
  config,
  xlib,
  ...
}:
{
  xlib.device.username = "oqyude";

  users = {
    users = {
      "${xlib.device.username}" = {
        isNormalUser = true;
        description = "Jor Oqyude";
        initialPassword = "1234";
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
      sshKeyPaths = [ "/etc/ssh/id_ed25519" ];
      generateKey = true;
    };
    defaultSopsFile = ../secrets/example.yaml;      # наш зашифрованный файл
    # Указываем секрет SSH-ключа:
    # secrets.ssh_key = {
    #   # формат секрета (YAML по умолчанию)
    #   format = "yaml";
    #   sopsFile = ../secrets/default.yaml;
    #   # (имя ключа в YAML: "ssh_key", т.е. ключ из файла выше)
    #   key = "ssh_key";

    #   path = "/home/test/.ssh/id_ed25519";
    #   owner = "root";   # владелец – наш пользователь
    #   group = "root";  # группа пользователя
    #   mode = "0600";                           # права 600
    # };
  };
}
