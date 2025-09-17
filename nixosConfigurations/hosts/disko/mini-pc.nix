{ xlib, ...}:
{
  disko.devices = {
    disk = {
      "${xlib.device.hostname}" = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            #boot = {
            #  type = "EF02";
            #  size = "1M";
            #;
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                extraArgs = [
                  "-L ${xlib.device.hostname}" # Filesystem label
                ];
              };
            };
            swap = {
              size = "2048M";
              content = {
                type = "swap";
              };
            };
          };
        };
      };
    };
  };
}
