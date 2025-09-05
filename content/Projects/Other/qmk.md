---
title: QMK Firmware + LoL
---

_(This project is split into 2 repositories due to the way QMK firmware needs to
be flashed onto your keyboard)_

- [League Frontend](https://github.com/zSuperx/league_keyboard)
- [Firmware Backend](https://github.com/zSuperx/qmk_league)

Despite all the jokes surrounding League of Legends and its community, the game
actually served as the source for one of my coolest projects.

My friend Advay and I created a program that syncs your QMK Keyboard's RGB
lights with your currently selected champion in League of Legends.

The project works by flashing some firmware we wrote onto your QMK Keyboard
(currently only the TKL QMK Keychron Ansi Encoder layout is supported). This
firmware provides some basic RGB customization through writing to USB channels
via HidAPI.

Once the firmware is flashed, the Python scripts in the repo can be run in the
background. This background process will then:

1. Detect when a League of Legends champion is locked in.
2. Send the associated color scheme through a HidAPI report, which changes the
   color of your keyboard!

## Todo

1. Clean up the QMK Firmware repo. The code can most probably stay the same, but
   I do want to ship a release package rather than requiring the user to
   recompile from source.
2. Rewrite the Python code. The HidAPI communication scripts are fine, but the
   repo is a mess right now.
3. **Change to use `uv` instead of global `pip` installations.**
