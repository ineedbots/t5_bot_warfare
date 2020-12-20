/*
	_bot_utility
	Author: INeedGames
	Date: 12/20/2020
	The shared functions for bots
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

/*
	Returns an array of all the bots in the game.
*/
getBotArray()
{
	result = [];
	playercount = level.players.size;
	for(i = 0; i < playercount; i++)
	{
		player = level.players[i];
		
		if(!player is_bot())
			continue;
			
		result[result.size] = player;
	}
	
	return result;
}

/*
	Returns a good amount of players.
*/
getGoodMapAmount()
{
	switch(getdvar("mapname"))
	{
		default:
			return 2;
	}
}

/*
	Rounds to the nearest whole number.
*/
Round(x)
{
	y = int(x);
	
	if(abs(x) - abs(y) > 0.5)
	{
		if(x < 0)
			return y - 1;
		else
			return y + 1;
	}
	else
		return y;
}

/*
	Picks a random thing
*/
PickRandom(arr)
{
	if (!arr.size)
		return undefined;

	return arr[randomInt(arr.size)];
}

/*
  Waits for a host player
*/
bot_wait_for_host()
{
	host = undefined;
	
	for(i = 0; i < 100; i++)
	{
		host = GetHostPlayer();
		
		if(isDefined(host))
			break;
		
		wait 0.05;
	}
	
	if(!isDefined(host))
		return;
	
	for(i = 0; i < 100; i++)
	{
		if(IsDefined( host.pers[ "team" ] ))
			break;
		
		wait 0.05;
	}

	if(!IsDefined( host.pers[ "team" ] ))
		return;
	
	for(i = 0; i < 100; i++)
	{
		if(host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis")
			break;
		
		wait 0.05;
	}
}
