![GitHub Logo](/main_shared/bw-assets/bw-logo.png)

# BO1 Bot Warfare
Bot Warfare is a GSC mod for [Black Ops 1](https://store.steampowered.com/app/42700/Call_of_Duty_Black_Ops/) (or [this](https://getrektby.us/)).

It aims to extend the existing AI in the multiplayer games of Black Ops 1.

You can find the ModDB release post [here](https://www.moddb.com/mods/bot-warfare/downloads/bo1-bot-warfare-latest).

## Contents
- [Features](#Features)
- [Installation](#Installation)
- [Documentation](#Documentation)
- [Changelog](#Changelog)
- [Credits](#Credits)

## Features
This mod extends the functionality and features of Combat Training in Black Ops multiplayer.

- Menu changes (combat training menu):
  - You can select any game mode.
  - You can change prestige classes if available.
  - You can change your clan tag, emblem and calling card.
  - You can prestige.
  - Increased limits of bot numbers.
    
- Bot changes:
  - Bots play all game modes (capture flags, plant and defuse, etc.).
  - Bots take out spyplanes and counter spyplanes.
  - Bots react to the uav, jammer, decoys, motion sensor and camera spike.
  - Bots can destroy tactical insertions.
  - Bots can call in chopper gunner and gun ship but do not use it.
  - Bots can hack claymores if they are not facing it.
  - Fixed bots never reviving a player if they move.
  - Fixed bots trying to capture a hacked care package when they can't because its on their team.
  - Silencers will not cause other bots to look in the firer's direction.
  - Bots class, rank, and cod points all persist across rounds.
  - Bots will spend cod points on everything they choose now (not just gun and perk like before).
  - Bots can choose two attachments if they have the perk.
  - Bots can skip killcams.
  - Bots have a slight delay after spawning, scales inversely with difficulty.
  - Bots can reroll carepackages.
  - Bots can use the valkyrie rocket carepackage streak.

## Installation
0. Download the [latest release](https://github.com/ineedbots/bo1_bot_warfare/releases) of Bot Warfare.
1. Locate the root folder which your game is installed in.
2. Move the files/folders found in 'Move to root of Black Ops folder' from the Bot Warfare release archive you downloaded to the root of your Black Ops folder.
    - The folder/file structure should follow as '.Black Ops folder\mods\mp_bots\mp_bots.iwd'.
3. The mod is now installed. Start your game, go to the 'Mods' menu and select 'mp_bots'.
4. The mod is now loaded! Go play Combat Training and enjoy the new additions.

## Documentation

### DVARs
- bots_manage_add - an integer amount of bots to add to the game, resets to 0 once the bots have been added.
    - for example: 'bots_manage_add 10' will add 10 bots to the game.

- bots_manage_fill - an integer amount of players/bots (depends on bots_manage_fill_mode) to retain on the server, it will automatically add bots to fill player space.
    - for example: 'bots_manage_fill 10' will have the server retain 10 players in the server, if there are less than 10, it will add bots until that value is reached.

- bots_manage_fill_mode - a value to indicate if the server should consider only bots or players and bots when filling player space.
    - 0 will consider both players and bots.
    - 1 will only consider bots.

- bots_manage_fill_kick - a boolean value (0 or 1), whether or not if the server should kick bots if the amount of players/bots (depends on bots_manage_fill_mode) exceeds the value of bots_manage_fill.

- bots_manage_fill_spec - a boolean value (0 or 1), whether or not if the server should consider players who are on the spectator team when filling player space.

---

- bots_team - a string, the value indicates what team the bots should join:
    - 'autoassign' will have bots balance the teams
    - 'allies' will have the bots join the allies team
    - 'axis' will have the bots join the axis team
    - 'custom' will have bots_team_amount bots on the axis team, the rest will be on the allies team
    
- bots_team_amount - an integer amount of bots to have on the axis team if bots_team is set to 'custom', the rest of the bots will be placed on the allies team.
    - for example: there are 5 bots on the server and 'bots_team_amount 3', then 3 bots will be placed on the axis team, the other 2 will be placed on the allies team.

- bots_team_force - a boolean value (0 or 1), whether or not if the server should enforce periodically the bot's team instead of just a single team when the bot is added to the game.
    - for example: 'bots_team_force 1' and 'bots_team autoassign' and the teams become to far unbalanced, then the server will change a bot's team to make it balanced again.

- bots_team_mode - a value to indicate if the server should consider only bots or players and bots when counting players on the teams.
    - 0 will consider both players and bots.
    - 1 will only consider bots.

---

- bots_loadout_reasonable - a boolean value (0 or 1), whether or not if the bots should filter out bad create a class selections

- bots_loadout_allow_op - a boolean value (0 or 1), whether or not if the bots are allowed to use jug, marty, etc.

- bots_loadout_rank - an integer number, bots will be around this rank, -1 is average of all players in game, 0 is all random

- bots_loadout_prestige - an integer number, bots will be this prestige, -1 is the same as player, -2 is all random

- bots_loadout_codpoints - an integer number, bots will be given this amount of codpoints, -1 is the around player, 0 is all random

- bots_play_move - a boolean value (0 or 1), whether or not if the bots will move
- bots_play_knife - a boolean value (0 or 1), whether or not if the bots will use the knife
- bots_play_fire - a boolean value (0 or 1), whether or not if the bots will fire their weapons
- bots_play_nade - a boolean value (0 or 1), whether or not if the bots will grenade
- bots_play_obj - a boolean value (0 or 1), whether or not if the bots will play the objective
- bots_play_camp - a boolean value (0 or 1), whether or not if the bots will camp
- bots_play_target_other - a boolean value (0 or 1), whether or not if the bots will target claymores, killstreaks, etc.
- bots_play_killstreak - a boolean value (0 or 1), whether or not if the bots will use killstreaks
- bots_play_take_carepackages - a boolean value (0 or 1), whether or not if the bots will take care packages

---

- bots_main - a boolean value (0 or 1), enables or disables the mod

- bots_main_waitForHostTime - a float value, how long in seconds to wait for the host player to connect before adding in bots

## Changelog
- v1.1.1
  - Fixed some script runtime errors
  - Improved domination
  - Bots use altmode weapons
  - Improved revenge
  - Bots can swap weapons on spawn more likely

- v1.1.0
  - Rewrote using CoD4x as a base
  - Fixed bots not knifing
  - Fixed several bugs, mainly with bot goals
  - New way of adding/managing bots, new dvars
  - Fixed bots force spawning
  - Fixed infinite loops and script errors

- v1.03
  - Fixed bots switching to secondaries all the time.
  - Bots can freely switch to their secondaries.
  - Fixed HCTDM scorelimit menu option.

- v1.02
  - Fixed a few small bugs. A possible infinite loop when bots are too poor for a grenade and reasonable setups are on, and bots never spawning after death with forcerespawn off.
  - Added an option to allow for UNLIMITED score.

- v1.01
  - Fixed bot's rank not updating after a multiround.
  - Can now set bot numbers for friends and enemies from 0 - 30 within menu. (15v15) (1v29)

- v1.0
  - Initial release.

## Credits
- INeedGames(me) - http://www.moddb.com/mods/bot-warfare
- apdonato - http://rsebots.blogspot.ca/

Feel free to use code, host on other sites, host on servers, mod it and merge mods with it, just give credit where credit is due!
  -INeedGames/INeedBot(s) @ ineedbots@outlook.com
