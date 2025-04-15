---
title: Wonderwall
---

[Project Link](https://github.com/zSuperx/wonderwall)

When I was a new user to the [Hyprland](https://hyprland.org/) ecosystem, I
noticed that a lot of basic tools (i.e. toolbars, wallpaper engines,
notification daemons, etc) were not included by default. While it was possible
(however tedious) to go find a lot of these applications, I took it as a
learning opportunity to understand some of these low-level processes work. I
created the Wonderwall wallpaper engine to help manage Hyprland’s underlying
wallpaper image setter [Hyprpaper](https://github.com/hyprwm/hyprpaper). It
allows cycling between the pictures in a chosen directory, manual updates, and
updating the pictures directory.

I am currently working on a way to remove the Hyprpaper dependency altogether
and eventually publish it as a Nix Flake.
