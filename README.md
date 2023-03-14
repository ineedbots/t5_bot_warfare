![GitHub Logo](/main_shared/bw-assets/bw-logo.png)

# BO1 Bot Warfare
Bot Warfare is a GSC mod for the steam version of [Black Ops 1](https://store.steampowered.com/app/42700/Call_of_Duty_Black_Ops/) (or the [Black Ops 1 Plutonium Client](https://plutonium.pw/)).

It aims to extend the existing bot AI aswell as improve upon the combat training mode in the multiplayer component of the game.

You can find the ModDB release post [here](https://www.moddb.com/mods/bot-warfare/downloads/bo1-bot-warfare-latest).

## Contents
- [Features](#Features)
- [Installation](#Installation)
- [Documentation](#Documentation)
- [Changelog](#Changelog)
- [Credits](#Credits)

## Features
This mod extends the capabilities of the ingame bots and enhances the functionality of the combat training mode in the multiplayer component of the game.

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

## Installation (For the Steam version of the game)
0. Download the latest release of this mod from either [GitHub](https://github.com/ineedbots/bo1_bot_warfare/releases) or [ModDB](https://www.moddb.com/mods/bot-warfare/downloads/bo1-bot-warfare-latest).
1. Locate the root folder which your game is installed in.
2. Move the files/folders found in 'Move to root of Black Ops folder' from the Bot Warfare release archive you downloaded to the root of your Black Ops folder.
    - The folder/file structure should follow as '.Black Ops folder\mods\mp_bots\mp_bots.iwd'.
3. The mod is now installed. Start Black Ops 1 Multiplayer, go to the 'Mods' menu and select 'mp_bots'.
4. The mod is now loaded! Go play Combat Training and enjoy the new additions.

## Installation (For the BO1 Plutonium Client)
 For BO1 Plutonium there are two different methods that can be used to install this mod. 
<br> <br>

### First Method - Recommended:
0. Download the latest release of this mod from either [GitHub](https://github.com/ineedbots/bo1_bot_warfare/releases) or [ModDB](https://www.moddb.com/mods/bot-warfare/downloads/bo1-bot-warfare-latest).
1. Press Windows+R on your keyboard and type %localappdata%\Plutonium\storage\t5 then press enter.
2. Move the mods folder found in 'Move to root of Black Ops folder' from the Bot Warfare release archive you downloaded to the folder you just opened in the previous step.
    - The folder/file structure should follow as '.Plutonium\storage\t5\mods\mp_bots\mp_bots.iwd'.
3. The mod is now installed. Start Black Ops 1 Multiplayer, go to the 'Mods' menu and select 'mp_bots'.
4. The mod is now loaded! Go play Combat Training and enjoy the new additions.

### Second Method - Advanced:
 This method is more complex and not recommended for those that wish to use this mod in combat training. This method of install has the advantage that the mod will autoload on game start and won't require other people to have this mod installed when connecting to your games.

0. Download the source code of the latest release of this mod from [GitHub](https://github.com/ineedbots/bo1_bot_warfare/releases)
1. Press Windows+R on your keyboard and type %localappdata%\Plutonium\storage\t5 then press enter.
2. Move the maps folder found in mods\mp_bots from the Bot Warfare source code archive you downloaded to the folder you just opened in the previous step.
    - The folder/file structure should follow as '.Plutonium\storage\t5\maps\mp\bots.
3. The mod is now installed. Start Black Ops 1 Multiplayer and launch a private match.
4. When ingame use the dvars below to spawn and configure the bots using the ingame console.

## Documentation

### DVARs
| Dvar                             | Description                                                                                 | Default Value |
|----------------------------------|---------------------------------------------------------------------------------------------|--------------:|
| bots_main                        | Enable this mod.                                                                            | true          |
| bots_main_waitForHostTime        | How many seconds to wait for the host player to connect before adding bots to the match.    | 10            |
| bots_main_kickBotsAtEnd          | Kick the bots at the end of a match.                                                        | false         |
| bots_manage_add                  | Amount of bots to add to the game, once bots are added, resets back to `0`.                 | 0             |
| bots_manage_fill                 | Amount of players/bots (look at `bots_manage_fill_mode`) to maintain in the match.          | 0             |
| bots_manage_fill_mode            | `bots_manage_fill` players/bots counting method.<ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots.</li></ul> | 0 |
| bots_manage_fill_kick            | If the amount of players/bots in the match exceeds `bots_manage_fill`, kick bots until no longer exceeds. | false |
| bots_manage_fill_spec            | If when counting players for `bots_manage_fill` should include spectators.                  | true          |
| bots_team                        | One of `autoassign`, `allies`, `axis`, `spectator`, or `custom`. What team the bots should be on. | autoassign |
| bots_team_amount                 | When `bots_team` is set to `custom`. The amount of bots to be placed on the axis team. The remainder will be placed on the allies team. | 0 |
| bots_team_force                  | If the server should force bots' teams according to the `bots_team` value. When `bots_team` is `autoassign`, unbalanced teams will be balanced. This dvar is ignored when `bots_team` is `custom`. | false |
| bots_team_mode                   | When `bots_team_force` is `true` and `bots_team` is `autoassign`, players/bots counting method. <ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots</li></ul> | 0 |
| bots_loadout_reasonable          | If the bots should filter bad performing create-a-class selections.                            | false      |
| bots_loadout_allow_op            | If the bots should be able to use overpowered and annoying create-a-class selections.          | true       |
| bots_loadout_rank                | What rank to set the bots.<ul><li>`-1` - Average of all players in the match.</li><li>`0` - All random.</li><li>`1` or higher - Sets the bots' rank to this.</li></ul> | -1 |
| bots_loadout_prestige            | What prestige to set the bots.<ul><li>`-1` - Same as host player in the match.</li><li>`-2` - All random.</li><li>`0` or higher - Sets the bots' prestige to this.</li></ul> | -1 |
| bots_loadout_codpoints           | Bots will be given this amount of codpoints to spend.<ul><li>`-1` - Average of all players in the match.</li><li>`0` - All random.</li><li>`1` or higher - Sets the bots' codpoints to this.</li></ul> | -1 |
| bots_play_move                   | If the bots can move.                                                                          | true       |
| bots_play_knife                  | If the bots can knife.                                                                         | true       |
| bots_play_fire                   | If the bots can fire.                                                                          | true       |
| bots_play_nade                   | If the bots can grenade.                                                                       | true       |
| bots_play_take_carepackages      | If the bots can take carepackages.                                                             | true       |
| bots_play_obj                    | If the bots can play the objective.                                                            | true       |
| bots_play_camp                   | If the bots can camp.                                                                          | true       |
| bots_play_target_other           | If the bots can target other entities other than players.                                      | true       |
| bots_play_killstreak             | If the bots can call in killstreaks.                                                           | true       |
| bots_play_aim                    | If the bots can aim.                                                                           | true       |

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
- INeedGames - http://www.moddb.com/mods/bot-warfare
- apdonato - http://rsebots.blogspot.ca/

Feel free to use code, host on other sites, host on servers, mod it and merge mods with it, just give credit where credit is due!
  -INeedGames/INeedBot(s) @ ineedbots@outlook.com
