---
title: Demonify
---

[Project Link](https://github.com/zSuperx/demonify)

I recently started getting into Raspberry Pi development, and I found it really
annoying to have to keep running the annoying
`nohup python3 example.py &>> ... &` command for each of my background programs
every time I wanted to restart the Pi. To remedy the problem, I wrote my own
simple wrapper tool that allows you to easily add/modify programs/commands to be
run on startup. It writes `.service` files that interact with Unix `systemd`.

More can be see on the project’s README, so go check it out!
