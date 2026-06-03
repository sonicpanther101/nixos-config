{config}: ''
  @define-color base00 #${config.lib.stylix.colors.base00};
  @define-color base01 #${config.lib.stylix.colors.base01};
  @define-color base02 #${config.lib.stylix.colors.base02};
  @define-color base03 #${config.lib.stylix.colors.base03};
  @define-color base05 #${config.lib.stylix.colors.base05};
  @define-color base0D #${config.lib.stylix.colors.base0D};
  @define-color base08 #${config.lib.stylix.colors.base08};

  /* =========================================
     RESET
     ========================================= */
  * {
    all: unset;
    font-family: 'Inter', 'Symbols Nerd Font Mono', sans-serif;
    font-size: 18px;
    color: @base05;
  }

  popover {
    background: alpha(@base01, 0.7);
    border: 1px solid alpha(@base0D, 0.15);
    border-radius: 12px;
    padding: 8px;
  }

  scrollbar { opacity: 0; }
  .normal-icons { -gtk-icon-size: 16px; }
  .large-icons { -gtk-icon-size: 32px; }

  /* =========================================
     OUTER WRAPPER — rounded
     ========================================= */
  .box-wrapper {
    background: alpha(@base00, 0.55);
    border: 1px solid alpha(@base0D, 0.15);
    border-radius: 16px;
    box-shadow: none;
    padding: 0;
    overflow: hidden;
  }

  /* =========================================
     SEARCH BAR — prominent top row
     ========================================= */
  .search-container {
    background: transparent;
    padding: 14px 18px;
    border-bottom: 1px solid alpha(@base0D, 0.1);
  }

  .search-icon {
    color: @base0D;
    -gtk-icon-size: 22px;
    opacity: 0.85;
  }

  .input {
    font-size: 28px;
    caret-color: @base0D;
    background: transparent;
    color: @base05;
    padding: 2px 0;
  }

  .input placeholder {
    opacity: 0.35;
    color: @base05;
  }

  .input selection {
    background: alpha(@base0D, 0.3);
  }

  .input:focus,
  .input:active {
  }

  /* =========================================
     CONTENT AREA
     ========================================= */
  .content-container {
  }

  /* =========================================
     LEFT LIST PANE — fixed width
     ========================================= */
  .scroll {
  }

  .list {
    color: @base05;
    padding: 4px 0;
  }

  .placeholder,
  .elephant-hint {
    color: @base05;
    font-size: 13px;
    opacity: 0.35;
    padding: 20px;
  }

  /* =========================================
     LIST ITEMS — compact icon + name
     ========================================= */
  child {
  }

  .item-box {
    padding: 6px 14px;
    border-radius: 8px;
    min-height: 44px;
  }

  child:selected .item-box,
  row:selected .item-box {
    background: alpha(@base0D, 0.12);
    border-radius: 8px;
  }

  .item-text-box {
  }

  .item-text {
    font-size: 18px;
  }

  .item-subtext {
    font-size: 14px;
    opacity: 0.45;
  }

  .item-image-text {
    font-size: 28px;
  }

  .item-quick-activation {
    background: alpha(@base02, 0.4);
    border-radius: 0;
    padding: 4px 8px;
    font-size: 11px;
    opacity: 0.5;
  }

  /* =========================================
     RIGHT PREVIEW PANE
     ========================================= */
  .preview {
    color: @base05;
    border: none;
    border-radius: 0;
  }

  .preview-box {
    color: @base05;
  }

  .preview .large-icons {
    -gtk-icon-size: 64px;
  }

  /* =========================================
     CALCULATOR — large result, muted expr
     ========================================= */
  .calc .item-text {
    font-size: 28px;
    font-weight: bold;
    color: @base0D;
  }

  .calc .item-subtext {
    font-size: 13px;
    opacity: 0.4;
    color: @base05;
  }

  /* =========================================
     SYMBOLS
     ========================================= */
  .symbols .item-image {
    font-size: 24px;
  }

  /* =========================================
     TODO
     ========================================= */
  .todo.done .item-text-box {
    opacity: 0.25;
  }

  .todo.urgent {
    font-size: 24px;
  }

  .todo.active {
    font-weight: bold;
  }

  /* =========================================
     BLUETOOTH
     ========================================= */
  .bluetooth.disconnected {
    opacity: 0.5;
  }

  /* =========================================
     PROVIDER LIST
     ========================================= */
  .providerlist .item-subtext {
    font-size: unset;
    opacity: 0.75;
  }

  /* =========================================
     KEYBINDS — hidden
     ========================================= */
  .keybinds {
    padding: 0;
    margin: 0;
    min-height: 0;
    opacity: 0;
  }

  .global-keybinds,
  .item-keybinds,
  .keybind,
  .keybind-button,
  .keybind-bind,
  .keybind-label {
    min-height: 0;
    padding: 0;
    margin: 0;
  }

  :not(.calc).current {
    font-style: italic;
  }

  /* =========================================
     ERROR BAR
     ========================================= */
  .error {
    padding: 10px 14px;
    background: @base08;
    color: @base05;
  }

  /* =========================================
     WALLPAPER ITEMS
     ========================================= */
  .wallpaper-item {
    padding: 8px;
    border-radius: 0;
  }

  .wallpaper-preview {
    min-height: 120px;
    min-width: 180px;
    border: 1px solid alpha(@base0D, 0.15);
  }

  .wallpaper-label {
    font-size: 12px;
    opacity: 0.75;
    padding-top: 6px;
  }

  child:selected .wallpaper-item {
    background: alpha(@base0D, 0.2);
  }

  /* =========================================
     PACKAGE PREVIEW
     ========================================= */
  .preview-content.archlinuxpkgs,
  .preview-content.dnfpackages {
    font-family: monospace;
  }
''