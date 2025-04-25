{
  config,
  ...
}:
{
  programs.keepassxc = {
    enable = true;
    settings = {
      General = {
        AutoSaveAfterEveryChange = false;
        AutoSaveNonDataChanges = false;
        AutoSaveOnExit = false;
        DropToBackgroundOnCopy = true;
        HideWindowOnCopy = true;
        MinimizeAfterUnlock = true;
        MinimizeOnCopy = false;
      };
      Browser = {
        AlwaysAllowAccess = true;
        Enabled = true;
      };
      GUI = {
        ApplicationTheme = "classic";
        CompactMode = true;
        HideMenubar = false;
        HideToolbar = false;
        HideUsernames = true;
        MinimizeOnClose = true;
        MinimizeOnStartup = true;
        MinimizeToTray = true;
        ShowTrayIcon = true;
        TrayIconAppearance = "colorful";
      };
    };
  };
}
