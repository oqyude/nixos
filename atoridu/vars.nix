rec {
  this-host = "atoridu";
  this-admin = "oqyude";
  dirs = rec {
    user-home = "/home/${this-admin}";
    home = "${user-home}";
    storage = "${home}/Storage";
  };
}
