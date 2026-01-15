{
  config,
  pkgs,
  ...
}:
{
  dconf = {
    settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          # dash-to-panel.extensionUuid
          # arcmenu.extensionUuid
          # vitals.extensionUuid
          appindicator.extensionUuid
        ];
        disabled-extensions = [ ];
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-light";
        enable-hot-corners = false;
      };
      "org/gnome/desktop/interface" = {
        scaling-factor = 1.5;
      };
    };
  };
  home = {
    packages = with pkgs; [
    ];
  };
}
