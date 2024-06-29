{
  image = "ghcr.io/thelolagemann/openrgb:latest";

  environment = {
    "TZ" = "Pacific/Auckland";
  };

  extraOptions = [
  "--rm"
  "--privileged"
  "-v /tmp/.X11-unix:/tmp/.X11-unix"
  "-v /config:/config"
  "-e DISPLAY=unix$DISPLAY"
  "-p 6742:6742"
  ];
}
