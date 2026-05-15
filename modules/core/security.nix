{ username, ... } : {
  security = {
    rtkit.enable = true;
    pam.services.hyprlock = {
      enable = true;
    };
    polkit.enable = true;
  };

  sops = {
    age.keyFile = "${username}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;  # path to your secrets file

    secrets.wakatime_api_key = {};  # declares the secret
  };
}