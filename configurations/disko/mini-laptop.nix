{ xlib, ... }:
{
  disko.devices = {
    disk = {
      "${xlib.device.hostname}" = {
        device = "/dev/nvme0n1p4";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
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
          };
        };
      };
    };
  };
}
