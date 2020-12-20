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
}

/*
  When the bot connects
*/
connected()
{
  self thread classWatch();
  self thread teamWatch();
}

/*
  Fired when the bot is damaged
*/
bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
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
		self.bot_change_class = true;
			
		while(isdefined(self.pers["team"]) && isdefined(self.pers["class"]) && isDefined(self.bot_change_class))
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
