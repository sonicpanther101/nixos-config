{ ... } : {
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      default-runtime = "nvidia";
      runtimes.nvidia = {
        path = "nvidia-container-runtime";
        runtimeArgs = [];
      };
    };
  };
}