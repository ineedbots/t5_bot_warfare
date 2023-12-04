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
	Waits for the built-ins to be defined
*/
wait_for_builtins()
{
	for ( i = 0; i < 20; i++ )
	{
		if ( isDefined( level.bot_builtins ) )
			return true;

		if ( i < 18 )
			waittillframeend;
		else
			wait 0.05;
	}

	return false;
}

/*
	Prints to console without dev script on
*/
BotBuiltinPrintConsole( s )
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "printconsole" ] ) )
	{
		[[ level.bot_builtins[ "printconsole" ] ]]( s );
	}
	else
	{
		PrintLn( s );
	}
}

/*
*/
BotBuiltinMovementOverride( a, b )
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botmovementoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botmovementoverride" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinClearMovementOverride()
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botclearmovementoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearmovementoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearButtonOverride( a )
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botclearbuttonoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearbuttonoverride" ] ]]( a );
	}
}

/*
*/
BotBuiltinButtonOverride( a, b )
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botbuttonoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botbuttonoverride" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinClearOverrides( a )
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botclearoverrides" ] ) )
	{
		self [[ level.bot_builtins[ "botclearoverrides" ] ]]( a );
	}
}

/*
*/
BotBuiltinMantleOverride()
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botmantleoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botmantleoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearMantleOverride()
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botclearmantleoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearmantleoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearWeaponOverride()
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botclearweaponoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearweaponoverride" ] ]]();
	}
}

/*
*/
BotBuiltinWeaponOverride( a )
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botweaponoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botweaponoverride" ] ]]( a );
	}
}

/*
*/
BotBuiltinClearButtonOverrides()
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botclearbuttonoverrides" ] ) )
	{
		self [[ level.bot_builtins[ "botclearbuttonoverrides" ] ]]();
	}
}

/*
*/
BotBuiltinAimOverride()
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botaimoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botaimoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearAimOverride()
{
	if ( isDefined( level.bot_builtins ) && isDefined( level.bot_builtins[ "botclearaimoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearaimoverride" ] ]]();
	}
}

/*
	Returns an array of all the bots in the game.
*/
getBotArray()
{
	result = [];
	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( !player is_bot() )
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
	switch ( getdvar( "mapname" ) )
	{
		default:
			return 2;
	}
}

/*
	Rounds to the nearest whole number.
*/
Round( x )
{
	y = int( x );

	if ( abs( x ) - abs( y ) > 0.5 )
	{
		if ( x < 0 )
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
PickRandom( arr )
{
	if ( !arr.size )
		return undefined;

	return arr[randomInt( arr.size )];
}

/*
	If is defusing
*/
isDefusing()
{
	return ( isDefined( self.isDefusing ) && self.isDefusing );
}

/*
	If is defusing
*/
isPlanting()
{
	return ( isDefined( self.isPlanting ) && self.isPlanting );
}

/*
	If is defusing
*/
inLastStand()
{
	return ( isDefined( self.laststand ) && self.laststand );
}

/*
	Is they the flag carrier men?
*/
isFlagCarrier()
{
	return ( isDefined( self.isFlagCarrier ) && self.isFlagCarrier );
}

/*
	If the site is in use
*/
isInUse()
{
	return ( isDefined( self.inUse ) && self.inUse );
}

/*
	If the player is carrying a bomb
*/
isBombCarrier()
{
	return ( isDefined( self.isBombCarrier ) && self.isBombCarrier );
}

/*
	iw5
*/
allowClassChoice()
{
	return true;
}

/*
	iw5
*/
allowTeamChoice()
{
	return true;
}

/*
	Gets the bot's difficulty number
*/
GetBotDiffNum()
{
	num = 0;

	switch ( getDvar( "bot_difficulty" ) )
	{
		case "fu":
			num = 3;
			break;

		case "hard":
			num = 2;
			break;

		case "normal":
			num = 1;
			break;

		case "easy":
		default:
			num = 0;
			break;
	}

	return num;
}

/*
	is the weapon alt mode?
*/
isWeaponAltmode( weap )
{
	if ( isStrStart( weap, "gl_" ) || isStrStart( weap, "ft_" ) || isStrStart( weap, "mk_" ) )
		return true;

	return false;
}

/*
	Returns a valid grenade launcher weapon
*/
getValidTube()
{
	weaps = self getweaponslist();

	for ( i = 0; i < weaps.size; i++ )
	{
		weap = weaps[i];

		if ( !self getAmmoCount( weap ) )
			continue;

		if ( ( isSubStr( weap, "gl_" ) && !isSubStr( weap, "_gl_" ) ) || weap == "china_lake_mp" )
			return weap;
	}

	return undefined;
}

/*
	Taken from iw4 script
*/
waittill_any_timeout( timeOut, string1, string2, string3, string4, string5 )
{
	if ( ( !isdefined( string1 ) || string1 != "death" ) &&
	    ( !isdefined( string2 ) || string2 != "death" ) &&
	    ( !isdefined( string3 ) || string3 != "death" ) &&
	    ( !isdefined( string4 ) || string4 != "death" ) &&
	    ( !isdefined( string5 ) || string5 != "death" ) )
		self endon( "death" );

	ent = spawnstruct();

	if ( isdefined( string1 ) )
		self thread waittill_string( string1, ent );

	if ( isdefined( string2 ) )
		self thread waittill_string( string2, ent );

	if ( isdefined( string3 ) )
		self thread waittill_string( string3, ent );

	if ( isdefined( string4 ) )
		self thread waittill_string( string4, ent );

	if ( isdefined( string5 ) )
		self thread waittill_string( string5, ent );

	ent thread _timeout( timeOut );

	ent waittill( "returned", msg );
	ent notify( "die" );
	return msg;
}

/*
	Used for waittill_any_timeout
*/
_timeout( delay )
{
	self endon( "die" );

	wait( delay );
	self notify( "returned", "timeout" );
}

/*
	Waits for a host player
*/
bot_wait_for_host()
{
	host = undefined;

	while ( !isDefined( level ) || !isDefined( level.players ) )
		wait 0.05;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		host = GetHostPlayer();

		if ( isDefined( host ) )
			break;

		wait 0.05;
	}

	if ( !isDefined( host ) )
		return;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( IsDefined( host.pers[ "team" ] ) )
			break;

		wait 0.05;
	}

	if ( !IsDefined( host.pers[ "team" ] ) )
		return;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis" )
			break;

		wait 0.05;
	}
}

/*
	Wrapper for setgoal
*/
SetBotGoal( where, dist )
{
	self SetScriptGoal( where, dist );
	waittillframeend;
	self notify( "new_goal" );
}

/*
	Weapper for cleargoal
*/
ClearBotGoal()
{
	self ClearScriptGoal();
	waittillframeend;
	self notify( "new_goal" );
}

/*
	Freezes bot in place
*/
botStopMove( what )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	self notify( "botStopMove" );
	self endon( "botStopMove" );

	if ( !what )
		return;

	og = self.origin;

	for ( ;; )
	{
		self setVelocity( ( 0, 0, 0 ) );
		self setOrigin( og );
		wait 0.05;
	}
}

/*
	Notify the bot chat message
*/
BotNotifyBotEvent( msg, a, b, c, d, e, f, g )
{
	self notify( "bot_event", msg, a, b, c, d, e, f, g );
}

/*
	Matches a num to a char
*/
keyCodeToString( a )
{
	b = "";

	switch ( a )
	{
		case 0:
			b = "a";
			break;

		case 1:
			b = "b";
			break;

		case 2:
			b = "c";
			break;

		case 3:
			b = "d";
			break;

		case 4:
			b = "e";
			break;

		case 5:
			b = "f";
			break;

		case 6:
			b = "g";
			break;

		case 7:
			b = "h";
			break;

		case 8:
			b = "i";
			break;

		case 9:
			b = "j";
			break;

		case 10:
			b = "k";
			break;

		case 11:
			b = "l";
			break;

		case 12:
			b = "m";
			break;

		case 13:
			b = "n";
			break;

		case 14:
			b = "o";
			break;

		case 15:
			b = "p";
			break;

		case 16:
			b = "q";
			break;

		case 17:
			b = "r";
			break;

		case 18:
			b = "s";
			break;

		case 19:
			b = "t";
			break;

		case 20:
			b = "u";
			break;

		case 21:
			b = "v";
			break;

		case 22:
			b = "w";
			break;

		case 23:
			b = "x";
			break;

		case 24:
			b = "y";
			break;

		case 25:
			b = "z";
			break;

		case 26:
			b = ".";
			break;

		case 27:
			b = " ";
			break;
	}

	return b;
}

/*
	Does the extra check when adding bots
*/
doExtraCheck()
{
	maps\mp\bots\_bot_script::checkTheBots();
}

/*
	Returns the cone dot (like fov, or distance from the center of our screen).
*/
getConeDot( to, from, dir )
{
	dirToTarget = VectorNormalize( to - from );
	forward = AnglesToForward( dir );
	return vectordot( dirToTarget, forward );
}

/*
	Fixes sd bomb planting
*/
bot_onUsePlantObjectFix( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bot_bombPlanted( self, player );
		player logString( "bomb planted: " + self.label );

		// disable all bomb zones except this one
		for ( index = 0; index < level.bombZones.size; index++ )
		{
			if ( level.bombZones[index] == self )
				continue;

			level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
		}

		thread playSoundOnPlayers( "mus_sd_planted" + "_" + level.teamPostfix[player.pers["team"]] );
// removed plant audio until finalization of assest TODO : new plant sounds when assests are online
//		player playSound( "mpl_sd_bomb_plant" );
		player notify ( "bomb_planted" );

		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_PLANTED_BY", player );

		if ( isdefined( player.pers["plants"] ) )
		{
			player.pers["plants"]++;
			player.plants = player.pers["plants"];
		}

		player maps\mp\_medals::saboteur();
		player maps\mp\gametypes\_persistence::statAddWithGameType( "PLANTS", 1 );

		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic_score::givePlayerScore( "plant", player );
		//player thread [[level.onXPEvent]]( "plant" );
	}
}

/*
	Fixes sd bomb planting
*/
bot_bombPlanted( destroyedObj, player )
{
	maps\mp\gametypes\_globallogic_utils::pauseTimer();
	level.bombPlanted = true;

	destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic_utils::playTickingSound( "mpl_sab_ui_suitcasebomb_timer" );
	//Play suspense music
	level thread maps\mp\gametypes\sd::bombPlantedMusicDelay();

	//thread maps\mp\gametypes\_globallogic_audio::actionMusicSet();

	level.tickingObject = destroyedObj.visuals[0];

	level.timeLimitOverride = true;
	setGameEndTime( int( gettime() + ( level.bombTimer * 1000 ) ) );
	setMatchFlag( "bomb_timer", 1 );

	if ( !level.multiBomb )
	{
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setDropped();
		level.sdBombModel = level.sdBomb.visuals[0];
	}
	else
	{

		for ( index = 0; index < level.players.size; index++ )
		{
			if ( isDefined( level.players[index].carryIcon ) )
				level.players[index].carryIcon destroyElem();
		}

		trace = bulletTrace( player.origin + ( 0, 0, 20 ), player.origin - ( 0, 0, 2000 ), false, player );

		tempAngle = randomfloat( 360 );
		forward = ( cos( tempAngle ), sin( tempAngle ), 0 );
		forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
		dropAngles = vectortoangles( forward );

		level.sdBombModel = spawn( "script_model", trace["position"] );
		level.sdBombModel.angles = dropAngles;
		level.sdBombModel setModel( "prop_suitcase_bomb" );
	}

	destroyedObj maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	/*
	    destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", undefined );
	    destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", undefined );
	    destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", undefined );
	    destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );
	*/
	label = destroyedObj maps\mp\gametypes\_gameobjects::getLabel();

	// create a new object to defuse with.
	trigger = destroyedObj.bombDefuseTrig;
	trigger.origin = level.sdBombModel.origin;
	visuals = [];
	defuseObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, ( 0, 0, 32 ) );
	defuseObject maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + label );
	defuseObject.label = label;
	defuseObject.onBeginUse = maps\mp\gametypes\sd::onBeginUse;
	defuseObject.onEndUse = maps\mp\gametypes\sd::onEndUse;
	defuseObject.onUse = maps\mp\gametypes\sd::onUseDefuseObject;
	defuseObject.useWeapon = "briefcase_bomb_defuse_mp";

	level.defuseObject = defuseObject;//every cod...

	player.isBombCarrier = false;

	maps\mp\gametypes\sd::BombTimerWait();
	setMatchFlag( "bomb_timer", 0 );

	destroyedObj.visuals[0] maps\mp\gametypes\_globallogic_utils::stopTickingSound();

	if ( level.gameEnded || level.bombDefused )
		return;

	level.bombExploded = true;



	explosionOrigin = level.sdBombModel.origin + ( 0, 0, 12 );
	level.sdBombModel hide();

	if ( isdefined( player ) )
	{
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_BLOWUP_BY", player );
		player maps\mp\_medals::bomber();
		player maps\mp\gametypes\_persistence::statAddWithGameType( "DESTRUCTIONS", 1 );
	}
	else
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, undefined, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );

	rot = randomfloat( 360 );
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + ( 0, 0, 50 ), ( 0, 0, 1 ), ( cos( rot ), sin( rot ), 0 ) );
	triggerFx( explosionEffect );

	thread playSoundinSpace( "mpl_sd_exp_suitcase_bomb_main", explosionOrigin );
	//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "SILENT", "both" );

	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );

	for ( index = 0; index < level.bombZones.size; index++ )
		level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();

	defuseObject maps\mp\gametypes\_gameobjects::disableObject();

	setGameEndTime( 0 );

	wait 3;

	maps\mp\gametypes\sd::sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
}
