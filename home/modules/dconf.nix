{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable { system = "x86_64-linux"; };
  last-stable = import inputs.nixpkgs-last-unstable { system = "x86_64-linux"; };
in
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
          dash-to-panel.extensionUuid
          arcmenu.extensionUuid
          vitals.extensionUuid
          appindicator.extensionUuid
        ];
        disabled-extensions = [ ];
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-light";
        enable-hot-corners = false;
      };
    };
  };
  home = {
    packages = with pkgs; [
    ];
  };
}
