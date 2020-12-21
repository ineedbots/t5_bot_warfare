/*
	_bot_script
	Author: INeedGames
	Date: 12/20/2020
	Tells the bots what to do.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
  When the bot is added to the game
*/
added()
{
	self maps\mp\bots\_bot_loadout::bot_get_cod_points();
	self maps\mp\bots\_bot_loadout::bot_get_rank();
	self maps\mp\bots\_bot_loadout::bot_get_prestige();
	
	self maps\mp\bots\_bot_loadout::bot_setKillstreaks();
	
	self.pers["bot"][ "cod_points_org" ] = self.pers["bot"][ "cod_points" ];//killstreaks cannot be set again

	self maps\mp\bots\_bot_loadout::bot_set_class();
}

/*
  When the bot connects
*/
connected()
{
  self thread classWatch();
  self thread teamWatch();

  self thread maps\mp\bots\_bot_loadout::bot_rank();
	self thread bot_skip_killcam();

  self thread bot_on_spawn();
	self thread bot_on_death();
}

/*
  Fired when the bot is damaged
*/
bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
}

/*
  When the bot dies
*/
bot_on_death()
{
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill("death");
		
		self.hasSpawned = false;
	}
}

/*
  Bots skip killcams
*/
bot_skip_killcam()
{
	level endon("game_ended");
	self endon("disconnect");
	
	for(;;)
	{
		wait 1;
		
		if(isDefined(self.killcam))
		{
			self notify("end_killcam");
			self clientNotify("fkce");
		}
	}
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]) || level.oldschool)
			wait .05;

		wait 0.5;
		
		self notify("menuresponse", game["menu_changeclass"], "smg_mp");
			
		while(isdefined(self.pers["team"]) && isdefined(self.pers["class"]))
			wait .05;
	}
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]))
			wait .05;
			
		wait 0.05;
		self notify("menuresponse", game["menu_team"], getDvar("bots_team"));
			
		while(isdefined(self.pers["team"]))
			wait .05;
	}
}

/*
  When bot spawns
*/
bot_on_spawn()
{
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill("spawned_player");
	}
}
