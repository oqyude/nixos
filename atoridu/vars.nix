rec {
  this-host = "atoridu";
  this-admin = "oqyude";

  dirs = rec {
    user-home = "/home/${this-admin}";
    home = "${user-home}";
    storage = "${home}/Storage";
  };

  platform = rec {
    cpu = "amd";
    vfioIds = [
      "10de:25a2"
      "10de:2291"
    ];
    gpuUsbDriverId = "0000:01:00.0"; # Nvidia
  };
}
