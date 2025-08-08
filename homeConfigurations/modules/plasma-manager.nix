{
  config,
  pkgs,
  ...
}:
{
  programs = {
    kate = {
      enable = true;
      editor = {
        brackets = {
          automaticallyAddClosing = true;
          highlightMatching = true;
        };
        font = {
          family = "Hack";
          pointSize = 14;
        };
      };
    };
    plasma = {
      enable = true;
      overrideConfig = false;
      configFile = {
        dolphinrc = {
          "General" = {
            "RememberOpenedTabs" = true;
          };
          "DetailsMode" = {
            "ExpandableFolders" = false;
            "PreviewSize" = 32;
            "IconSize" = 32;
          };
        };
        "katerc" = {
          "KTextEditor View" = {
            "Scroll Bar MiniMap" = false;
            "Scroll Bar Preview" = false;
          };
        };
      };
      input = {
        # /proc/bus/input/devices
        mice = [
          {
            acceleration = -0.2;
            accelerationProfile = "none";
            enable = true;
            leftHanded = false;
            middleButtonEmulation = false;
            name = "Logitech USB Receiver Mouse";
            naturalScroll = false;
            productId = "c548";
            scrollSpeed = 1;
            vendorId = "046d";
          }
        ];
        touchpads = [
          {
            accelerationProfile = "none";
            disableWhileTyping = true;
            enable = true;
            leftHanded = true;
            middleButtonEmulation = false;
            name = "ELAN1203:00 04F3:307A Touchpad";
            naturalScroll = true;
            pointerSpeed = 0;
            productId = "307a";
            rightClickMethod = "bottomRight";
            scrollMethod = "twoFingers";
            tapDragLock = false;
            tapToClick = true;
            twoFingerTap = "rightClick";
            vendorId = "04f3";
          }
        ];
        keyboard = {
          switchingPolicy = "global";
          #           options = [
          #             "altshift"
          #           ];
          layouts = [
            {
              layout = "us";
            }
            {
              layout = "ru";
            }
          ];
        };
      };
      workspace = {
        #clickItemTo = "open"; # If you liked the click-to-open default from plasma 5
        lookAndFeel = "com.github.vinceliuice.WhiteSur-alt";
        colorScheme = "WhiteSurAlt";
        theme = "WhiteSur-Alt";
        iconTheme = "WhiteSur";
        cursor = {
          theme = "Qogir";
          size = 24;
        };
        #wallpaper = "${config.home.homeDirectory}//Misc/Desktops/Wallpapers/Desktop/END_Circle_7.png";
        #windowDecorations = {
        #  library = "org.kde.kwin.aurorae";
        #  theme = "__aurorae__svg__WhiteSur";
        #};
      };
      kwin = {
        edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
        cornerBarrier = false;
        #scripts.polonium.enable = true;
        nightLight = {
          enable = true;
          mode = "constant";
          temperature.night = 5800;
        };
        effects.shakeCursor.enable = false;
        virtualDesktops = {
          number = 2;
          rows = 1;
        };
      };
    };
  };
}
