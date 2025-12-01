let
  browser = "vivaldi.desktop";
  editor = "codium.desktop";
  file-manager = "nemo.desktop";
  image-viewer = "imv.desktop";
  image-editor = "pinta.desktop";
  torrent = "org.qbittorrent.qBittorrent.desktop";
in {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = file-manager;

        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "application/xhtml+xml" = browser;
        "text/html" = browser;

        "x-scheme-handler/magnet" = torrent;
        "application/x-bittorrent" = torrent;
        "application/pdf" = browser;
        "application/x-shellscript" = editor;

        "image/jpeg" = image-viewer;
        "image/bmp" = image-viewer;
        "image/gif" = image-viewer;
        "image/jpg" = image-viewer;
        "image/pjpeg" = image-viewer;
        "image/png" = image-viewer;
        "image/tiff" = image-viewer;
        "image/webp" = image-viewer;
        "image/x-bmp" = image-viewer;
        "image/x-gray" = image-viewer;
        "image/x-icb" = image-viewer;
        "image/x-ico" = image-editor;
        "image/x-png" = image-editor;
        "image/x-portable-anymap" = image-viewer;
        "image/x-portable-bitmap" = image-viewer;
        "image/x-portable-graymap" = image-viewer;
        "image/x-portable-pixmap" = image-viewer;
        "image/x-xbitmap" = image-viewer;
        "image/x-xpixmap" = image-viewer;
        "image/x-pcx" = image-viewer;
        "image/svg+xml" = image-viewer;
        "image/svg+xml-compressed" = image-viewer;
        "image/vnd.wap.wbmp" = image-viewer;
        "image/x-icns" = image-viewer;
      };
      associations = {
        added = {
          "inode/directory" = file-manager;

          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "application/xhtml+xml" = browser;
          "text/html" = browser;

          "x-scheme-handler/magnet" = torrent;
          "application/x-bittorrent" = torrent;
          "application/pdf" = browser;
          "application/x-shellscript" = editor;

          "image/jpeg" = image-editor;
          "image/bmp" = image-viewer;
          "image/gif" = image-viewer;
          "image/jpg" = image-viewer;
          "image/pjpeg" = image-viewer;
          "image/png" = image-editor;
          "image/tiff" = image-viewer;
          "image/webp" = image-editor;
          "image/x-bmp" = image-viewer;
          "image/x-gray" = image-viewer;
          "image/x-icb" = image-viewer;
          "image/x-ico" = image-editor;
          "image/x-png" = image-editor;
          "image/x-portable-anymap" = image-viewer;
          "image/x-portable-bitmap" = image-viewer;
          "image/x-portable-graymap" = image-viewer;
          "image/x-portable-pixmap" = image-viewer;
          "image/x-xbitmap" = image-viewer;
          "image/x-xpixmap" = image-viewer;
          "image/x-pcx" = image-viewer;
          "image/svg+xml" = image-viewer;
          "image/svg+xml-compressed" = image-viewer;
          "image/vnd.wap.wbmp" = image-viewer;
          "image/x-icns" = image-viewer;
        };
      };
    };

    # Force the change to override existing defaults
    configFile."mimeapps.list".force = true;

  };

}