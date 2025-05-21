---
title: Proxytunnel Nix Flake
---

## Proxytunnel

Proxytunnel is a program that securely connects `stdin` and `stdout` across SSH
using the HTTPS proxy.

[Official Github Link](https://github.com/proxytunnel/proxytunnel)

Since Proxytunnel is not in the `nixpkgs` repo, I created a simple Nix Flake so
Nix users can build and install it.

## Standalone Nix Shell

To create a temporary Nix Shell with access to the `proxytunnel` binary, you can
run the command:

```console
nix develop github:proxytunnel/proxytunnel
```

## Nix Flake Input

If you instead want to include it as a flake input, the following `flake.nix`
shows how to do so:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add proxytunnel as an input
    proxytunnel.url = "github:proxytunnel/proxytunnel";
  };
  outputs = {
    nixpkgs,
    proxytunnel,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [
          # Add proxytunnel's default features to your nixpkgs
          proxytunnel = proxytunnel.overlays.default;
          # For a full list of override options, see `nix/proxytunnel.nix`
      ];
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [ 
        # Make the `proxytunnel` binary available in a Nix Shell
        pkgs.proxytunnel

        # And include any other packages as desired...
        pkgs.hello
        # ...
      ];
    };
  };
}
```
