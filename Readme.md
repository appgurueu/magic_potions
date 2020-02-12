# Magic Potions (`magic_potions`)

Magic potions which grant the player temporary effects.

## About

Help can be found under `config_help.md` in the same folder as this.

Depends on the latest [`modlib`](https://github.com/appgurueu/modlib) and [`hud_timers`](https://github.com/appgurueu/hud_timers).

Code licensed under the MIT license. Written by Lars Mueller alias LMD or appguru(eu).

## Links

* [GitHub](https://github.com/appgurueu/magic_potions) - sources, issue tracking, contributing
* [Discord](https://discordapp.com/invite/ysP74by) - discussion, chatting
* [Minetest Forum](https://forum.minetest.net/viewtopic.php?f=9&t=24208) - (more organized) discussion
* [ContentDB](https://content.minetest.net/packages/LMD/magic_potions/) - releases (cloning from GitHub is recommended)

## Screenshots

![Screenshot](screenshot.png)

## Setup

Install the mod like any other, using `git clone https://github.com/appgurueu/magic_potions.git` or installing via ContentDB & the in-game content manager. Enable it, `modlib` & `hud_timers` and you're ready to enjoy some potions!

## Features

There are 3 levels of strength, from minor (weak) over ordinary (medium) to strong (best).

5 different potion types provide flying (antigravity), jumping (higher), (running) speed, healing (regeneration) and air (breathing, breath regen).

This makes for a total of 15 colorful potions. All effects are lost on death, and you can only use 3 at a time. They all have limited durations.

## API

Mostly self-documenting code. Mod namespace is `magic_potions`, containing all variables & functions.