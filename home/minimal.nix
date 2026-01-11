{
  config,
  pkgs,
  ...
}:
{
  programs = {
    btop.enable = true;
    broot.enable = true;
    bottom.enable = true;
    fastfetch.enable = true;
    yazi = {
      enable = true;
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
      flavors = {
        nord = pkgs.yaziPlugins.nord;
      };
      theme = {
        flavor = {
          light = "nord";
          dark = "nord";
        };
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
            on = [
              "g"
              "C"
            ];
            desc = "Compress with ouch";
          }
        ];
      };
      settings = {
        mgr.ratio = [
          1
          1
          4
        ];
      };
    };
  };
}
