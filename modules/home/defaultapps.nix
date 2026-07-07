{ ... }:

let
  browser = "vivaldi-stable.desktop";
  editor = "codium.desktop";
  file-manager = "nemo.desktop";
  image-viewer = "imv.desktop";
  image-editor = "pinta.desktop";
  video-viewer = "mpv.desktop";
  video-viewer-extra = "vlc.desktop";
  video-editor = "handbrake.desktop";
  torrent = "org.qbittorrent.qBittorrent.desktop";
  archive-manager = "org.gnome.FileRoller.desktop";
in {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = file-manager;

        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/ftp" = browser;
        "x-scheme-handler/chrome" = browser;
        "text/html" = browser;
        "application/x-extension-htm" = browser;
        "application/x-extension-html" = browser;
        "application/x-extension-shtml" = browser;
        "application/xhtml+xml" = browser;
        "application/x-extension-xhtml" = browser;
        "application/x-extension-xht" = browser;

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

        "video/mp4" = video-viewer;
        "video/x-matroska" = video-viewer;      # mkv
        "video/webm" = video-viewer;
        "video/x-msvideo" = video-viewer;       # avi
        "video/quicktime" = video-viewer;       # mov
        "video/x-flv" = video-viewer;
        "video/x-ms-wmv" = video-viewer;
        "video/mpeg" = video-viewer;
        "video/3gpp" = video-viewer;
        "video/ogg" = video-viewer;
        "video/MP2T" = video-viewer;            # ts
        "video/mp2t" = video-viewer;
        
        "application/vnd.rn-realmedia" = video-viewer-extra;
        "video/x-ms-asf" = video-viewer-extra;
        "video/x-ms-wm" = video-viewer-extra;
        "video/x-fli" = video-viewer-extra;
        
        "video/x-raw" = video-editor;
        "application/mxf" = video-editor;
        "video/x-mxf" = video-editor;
        "application/vnd.apple.prores" = video-editor;

        # ZIP
        "application/zip" = archive-manager;
        "application/x-zip-compressed" = archive-manager;

        # 7z
        "application/x-7z-compressed" = archive-manager;

        # RAR
        "application/vnd.rar" = archive-manager;
        "application/x-rar" = archive-manager;
        "application/x-rar-compressed" = archive-manager;

        # Tar
        "application/x-tar" = archive-manager;

        # gzip
        "application/gzip" = archive-manager;
        "application/x-gzip" = archive-manager;

        # bzip2
        "application/x-bzip2" = archive-manager;

        # xz
        "application/x-xz" = archive-manager;

        # tar.gz / tgz
        "application/x-compressed-tar" = archive-manager;
        "application/x-gtar" = archive-manager;

        # tar.xz
        "application/x-xz-compressed-tar" = archive-manager;

        # tar.bz2
        "application/x-bzip-compressed-tar" = archive-manager;

        # Zstandard
        "application/zstd" = archive-manager;
        "application/x-zstd" = archive-manager;
        "application/x-zstd-compressed-tar" = archive-manager;
      };
    };
  };
}