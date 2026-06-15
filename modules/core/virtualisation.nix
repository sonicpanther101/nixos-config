{ ... } : {
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      features.cdi = true;
      cdi-spec-dirs = [ "/etc/cdi" ];
      default-runtime = "nvidia";
      runtimes.nvidia = {
        path = "nvidia-container-runtime";
        runtimeArgs = [];
      };
    };
  };
}