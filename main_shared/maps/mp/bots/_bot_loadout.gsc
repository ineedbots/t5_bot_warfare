/*
	_bot_loadout
	Author: INeedGames
	Date: 12/20/2020
  Loadout stuff
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
  Gives the bot loadout
*/
bot_give_loadout()
{
  if (!isDefined(self.bot))
		self.bot = [];
    
  self.bot[ "specialty1" ] = "specialty_null";
	self.bot[ "specialty2" ] = "specialty_null";
	self.bot[ "specialty3" ] = "specialty_null";

  self.cac_body_type = "standard_mp";
  self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
	self.cac_hat_type = "none";
	self maps\mp\gametypes\_armor::set_player_model();

  self GiveWeapon( "ak47_mp", 0, 0 );
}
