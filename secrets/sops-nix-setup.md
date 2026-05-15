# sops-nix Setup Guide

Secrets are stored **encrypted** in the repo using [sops-nix](https://github.com/Mic92/sops-nix) and decrypted to `/run/secrets/` at login. No plaintext secrets ever touch the repo.

---

## 1. Generate an age key

```bash
nix shell nixpkgs#age
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Note the **public key** printed to stdout — you'll need it in the next step.

> Keep `~/.config/sops/age/keys.txt` out of the repo. Back it up in a password manager.

---

## 2. Add sops-nix to flake.nix

```nix
inputs = {
  sops-nix.url = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows = "nixpkgs";
};
```

Then import the module. For **home-manager**:

```nix
# in your homeConfigurations outputs
extraSpecialArgs = { inherit inputs; };

# in home.nix
imports = [ inputs.sops-nix.homeManagerModules.sops ];
```

For **NixOS system-level**:

```nix
modules = [ inputs.sops-nix.nixosModules.sops ];
```

---

## 3. Create .sops.yaml in the repo root

```yaml
keys:
  - &me age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
        - *me
```

Replace the `age1...` value with your actual public key.

---

## 4. Create and encrypt a secrets file

```bash
mkdir -p secrets
nix shell nixpkgs#sops
sops secrets/secrets.yaml
```

Write secrets as plain YAML in the editor — sops encrypts on save:

```yaml
wakatime_api_key: waka_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Commit `secrets/secrets.yaml` to the repo. It is safe to do so — it's encrypted.

---

## 5. Declare secrets in home.nix

```nix
sops = {
  age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  defaultSopsFile = ../../secrets/secrets.yaml;

  secrets.wakatime_api_key = {};
};
```

The decrypted secret will be available at `config.sops.secrets.wakatime_api_key.path` at runtime.

---

## 6. Reference the secret in your config

```nix
{ config, ... }:
{
  programs.vscode.userSettings = {
    "WakaTime.ApiKey" = config.sops.secrets.wakatime_api_key.path;
  };
}
```

---

## Common tasks

**Edit secrets:**
```bash
sops secrets/secrets.yaml
```

**Add a new machine:** Add its age public key to `.sops.yaml`, then re-encrypt:
```bash
sops updatekeys secrets/secrets.yaml
```

**Get a machine's age key from its SSH host key** (useful for NixOS systems):
```bash
nix shell nixpkgs#ssh-to-age
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```
