---
title: Home
---

Hey there, my name is zSuper. I love making OS-level tools, Discord Bots, and
other fun projects such as this website. I hope you enjoy your stay!

## My Links

- [LinkedIn](https://linkedin.com/in/piyush-kumbhare)
- [Github](https://github.com/zSuperx)
- [My Discord Development Server](https://discord.gg/xaNgH27evH)

## Pinned Projects

Here are some of my pinned projects. I try my best to maintain them, and I'm
constantly looking for ways to improve them.

To see all my projects, check out the [Projects](./Projects/) tab or my
[Github repositories](https://github.com/zSuperx?tab=repositories).

### Custom Compression Tool

This is a custom compression program I wrote that's based on `bzip2`. I wrote
almost everything in this project from scratch in Rust. It currently has an
average compression rate of ~70% (on large files) and supports variable encoding
schemes.

Click [here](./Projects/compression.md) for more info.

### Wonderwall (Custom Wallpaper Engine)

When I first started using [Hyprland](https://hyprland.org/), I noticed that
tools like toolbars, wallpaper engines, notification daemons, etc were not
included by default. As a result, I created the Wonderwall wallpaper engine to
help manage Hyprland’s underlying wallpaper image setter
[Hyprpaper](https://github.com/hyprwm/hyprpaper).

Click [here](./Projects/wonderwall.md) for more info.

### Demonify (Custom Systemd Manager)

As I got more into Raspberry Pi development, I wrote my own simple wrapper tool
to allow easy management of programs/commands to be run on startup. It works by
creating `.service` files that interact with Unix `systemd`.

Click [here](./Projects/demonify.md) for more info.

## NixOS Dotfiles

Yes, "I use NixOS (btw)"! But jokes aside, I do have a public dotfiles repo,
which can be seen [here](https://github.com/zSuperx/dotfiles).

### What is Nix?

If you don't know what [Nix/NixOS](https://nixos.wiki/wiki/Nix_package_manager)
is, it's a package manager that guarantees reproducibility! It works by parsing
a `.nix` files with specific instructions on what packages, options, systemd
services, etc. should be enabled. Then, when you run a Nix rebuild command,
you're essentially telling Nix to "re-evaluate" the `.nix` file and follow its
exact instructions on what to build your system with. NixOS is simply this idea
but taken to the extreme, and uses Nix paradigms to define an entire functioning
operating system!

On top of this, Nix Flakes are a way to guarantee even more reproducibility by
specifying what build inputs you use, down to the exact version, URL, or even
commit hash! This way you'll never face the issue of

> "Oh, it works on your system, but not mine :("

### My Configuration

My configuration is highly centered around the [Hyprland](https://hyprland.org)
window manager program. It's a tiling window manager that offers nearly infinite
customizability on how to display and move windows around. Paired with Nix, my
[dotfiles](https://github.com/zSuperx/dotfiles) repo serves as a view into
exactly what config options I use, down to the exact settings I use in
applications like Neovim!
