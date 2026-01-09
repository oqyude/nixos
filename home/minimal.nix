{
  config,
  pkgs,
  ...
}:
{
  # gtk = {
  #   enable = true;
  #   #Icon Theme
  #   iconTheme = {
  #     package = pkgs.adwaita-icon-theme;
  #     name = "Adwaita";
  #     # package = pkgs.kdePackages.breeze-icons;
  #     # name = "Breeze-Dark";
  #   };
  # };
  programs = {
    btop.enable = true;
    broot.enable = true;
    bottom.enable = true;
    fastfetch.enable = true;
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      plugins = {
        inherit (pkgs.yaziPlugins)
          gitui
          git
          sudo
          ouch
          rsync
          diff
          mount
          chmod
          dupes
          lazygit
          toggle-pane
          rich-preview
          smart-filter
          full-border
          recycle-bin
          ;
      };
      theme = {
        flavor = {
          light = "nord";
          dark = "nord";
        }; 
      };
      flavors = {
        inherit (pkgs.yaziPlugins) nord;
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [
              "g"
              "i"
            ];
            run = "plugin lazygit";
            desc = "run lazygit";
          }
          {
            run = "plugin ouch --args=zip";
            on = [ "g" "C" ];
            desc = "Compress with ouch";
          }
        ];
      };
    };
  };
}
