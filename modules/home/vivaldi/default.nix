{ lib, pkgs-unstable, ... } :
let
  friendlyWebPanels = [
    {
      faviconUrl = "";
      faviconUrlValid = true;
      id = "WEBPANEL_1f73d252-0717-477e-81d4-e7dc887c6232";
      mobileMode = true;
      origin = "user";
      resizable = false;
      title = "Google Translate";
      url = "https://translate.google.com/?sl=en&tl=ja&op=translate";
      width = -1;
      zoom = 1;
    }
  ];

  catppuccinTheme = {
    accentFromPage = false;
    accentOnWindow = true;
    accentSaturationLimit = 1;
    alpha = 0.88;
    backgroundImage = "";
    backgroundPosition = "stretch";
    blur = 5;
    colorAccentBg = "#1e1e2e";
    colorBg = "#1e1e2e";
    colorFg = "#CDD6F4";
    colorHighlightBg = "#89B4FA";
    colorWindowBg = "#1e1e2e";
    contrast = 0;
    dimBlurred = false;
    engineVersion = 1;
    id = "994de9f0-2b5b-46c0-bf42-fbc39c7a0226";
    name = "Catppuccin Mocha Blue";
    preferSystemAccent = false;
    radius = 4;
    simpleScrollbar = false;
    transparencyTabBar = false;
    transparencyTabs = false;
    url = "";
    version = 1;
  };

  prefs = {
    vivaldi = {
      tabs = {
        bar = {
          position = 1; # 1 = left
          width = 106;
        };
        stacking.open_accordions = [];
        counter_detection = true;
      };

      panels = {
        position = 0;
        show_toggle = true;
        elements = [
          { id = "PanelBookmarks";    resizable = false; width = -1; }
          { id = "PanelReadingList";  resizable = false; width = -1; }
          { id = "PanelDownloads";    resizable = false; width = -1; }
          { id = "PanelHistory";      resizable = false; width = -1; }
          { id = "PanelNotes";        resizable = false; width = -1; }
          { id = "PanelWindow";       resizable = false; width = -1; }
          { id = "PanelTranslate";    resizable = false; width = -1; }
          { id = "PanelCalendar";     resizable = false; width = -1; }
          { id = "PanelTasks";        resizable = false; width = -1; }
        ];
        web = {
          elements = friendlyWebPanels;
          removed_elements = [];
        };
        window_defaults = {
          barVisible = true;
          contentVisible = false;
          width = 931;
        };
      };

      toolbars = {
        navigation = [
          "PanelToggle"
          "PanelWidthSpacer"
          "Back"
          "Forward"
          "Reload"
          "AddressField"
          "TilingToggle"
          "Zoom"
          "Extensions"
          "UpdateButton"
          "AccountButton"
        ];
        panel = [
          "PanelBookmarks"
          "PanelDownloads"
          "PanelHistory"
          "WEBPANEL_1f73d252-0717-477e-81d4-e7dc887c6232"
          "PanelWindow"
          "PanelReadingList"
          "PanelTasks"
          "PanelCalendar"
          "PanelWeb"
          "FlexibleSpacer"
          "Settings"
        ];
        status = [
          "Settings" "BreakMode" "SyncStatus" "MailStatus" "CalendarStatus"
          "StatusInfo" "VersionInfo" "AutoHideToggle" "CaptureImages"
          "PageActions" "Zoom" "Clock"
        ];
      };

      themes = {
        current = "994de9f0-2b5b-46c0-bf42-fbc39c7a0226";
        user = [ catppuccinTheme ];
      };

      theme = {
        schedule.enabled = 0;
        simple_scrollbar = false;
      };

      startpage = {
        navigation = 2;
        speed_dial = {
          add_button_visible = false;
          restore_page_id = "-99";
        };
      };

      status_bar = {
        display = 1;
        minimized = 0;
      };

      appearance = {
        disable_title_bar = true;
        tree_columns.entries = {};
      };

      menu = {
        display = 0;
        icon_type = 0;
      };
    };

    account_values.vivaldi = {
      tabs = {
        active_min_size = 30;
        align_next = true;
        always_load_pinned_after_restore = true;
        at_edge = true;
        bar = { height = 150; slider_xpos = 131; width = 106; };
        close_button_permanent = false;
        confirm_closing_tabs = false;
        counter_detection = true;
        dim_hibernated = true;
        minimize = false;
        never_close_last = false;
        new_page.link = 0;
        new_placement = 0;
        thumbnails = false;
        visual_switch = { enable = true; list_layout = true; };
      };
      panels = {
        as_overlay = { auto_close = true; enabled = true; };
        show_close_button = false;
        show_folder_badge = true;
        show_toggle = true;
        translate.automatic = true;
        window.show_unread = true;
      };
      mouse_gestures = {
        enabled = true;
        rocker_gestures.enabled = true;
      };
      mouse_wheel.tab_switch = true;
      startpage.speed_dial = {
        add_button_visible = false;
        controls_visible = false;
        delete_visible = false;
        display_search = false;
        favicon_visible = false;
        game_button_show = false;
        titles_visible = 0;
      };
    };
  };

in {
  home.activation.vivaldSeedPreferences = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PREFS="$HOME/.config/vivaldi/Default/Preferences"

    if [ ! -f "$PREFS" ]; then
      mkdir -p "$HOME/.config/vivaldi/Default"
      cat > "$PREFS" << 'ENDOFPREFS'
${builtins.toJSON prefs}
ENDOFPREFS
      echo "Vivaldi: seeded initial preferences"
    fi
  '';

  programs.chromium = {
    enable = true;
    package = pkgs-unstable.vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = true;
    };
    extensions = [ 
      "clngdbkpkpeebahjckkjfobafhncgmne"  # Stylus
      "eimadpbcbfnmbkopoojfekhnkhdbieeh"  # Dark Reader
      "bppajinomefndbbmopljhbdfefnefdha"  # Consumer Rights Wiki
      "cjpalhdlnbpafiamejdnhcphjbkeiagm"  # uBlock Origin
    ];
    commandLineArgs = [
      "--enable-features=WebRTCPipeWireCapturer"
      "--ozone-platform=wayland"
      # "--disable-component-update" Enable to stop extensions from updating
    ];
  };


}