{ host, ... } : {
  imports = [
    ./foobar2000.nix
  ];
  # ++ (if someCondition then [ ./optional.nix ] else []);
}
