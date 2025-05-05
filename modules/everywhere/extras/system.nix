{
  config,
  ...
}:
{
  security = {
    sudo.wheelNeedsPassword = false;
    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
            if ((action.id == "org.gnome.gparted" || // for gnome
                action.id == "org.freedesktop.policykit.exec") && // for desktop, nekoray
                subject.isInGroup("wheel")){ // for sudo
                return polkit.Result.YES;
            }
        });
      '';
    };
  };
  systemd.network.wait-online.enable = false;
}
