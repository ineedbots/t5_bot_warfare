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
		if ( isdefined( level.bot_builtins ) )
		{
			return true;
		}
		
		if ( i < 18 )
		{
			waittillframeend;
		}
		else
		{
			wait 0.05;
		}
	}
	
	return false;
}

/*
	Prints to console without dev script on
*/
BotBuiltinPrintConsole( s )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "printconsole" ] ) )
	{
		[[ level.bot_builtins[ "printconsole" ] ]]( s );
	}
	else
	{
		println( s );
	}
}

/*
*/
BotBuiltinMovementOverride( a, b )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botmovementoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botmovementoverride" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinClearMovementOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearmovementoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearmovementoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearButtonOverride( a )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearbuttonoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearbuttonoverride" ] ]]( a );
	}
}

/*
*/
BotBuiltinButtonOverride( a, b )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botbuttonoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botbuttonoverride" ] ]]( a, b );
	}
}

/*
*/
BotBuiltinClearOverrides( a )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearoverrides" ] ) )
	{
		self [[ level.bot_builtins[ "botclearoverrides" ] ]]( a );
	}
}

/*
*/
BotBuiltinMantleOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botmantleoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botmantleoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearMantleOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearmantleoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearmantleoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearWeaponOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearweaponoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearweaponoverride" ] ]]();
	}
}

/*
*/
BotBuiltinWeaponOverride( a )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botweaponoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botweaponoverride" ] ]]( a );
	}
}

/*
*/
BotBuiltinClearButtonOverrides()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearbuttonoverrides" ] ) )
	{
		self [[ level.bot_builtins[ "botclearbuttonoverrides" ] ]]();
	}
}

/*
*/
BotBuiltinAimOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botaimoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botaimoverride" ] ]]();
	}
}

/*
*/
BotBuiltinClearAimOverride()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botclearaimoverride" ] ) )
	{
		self [[ level.bot_builtins[ "botclearaimoverride" ] ]]();
	}
}

/*
	Sets melee params
*/
BotBuiltinBotMeleeParams( yaw, dist )
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "botmeleeparams" ] ) )
	{
		self [[ level.bot_builtins[ "botmeleeparams" ] ]]( yaw, dist );
	}
}

/*
*/
BotBuiltinClearMeleeParams()
{
	if ( isdefined( level.bot_builtins ) && isdefined( level.bot_builtins[ "clearbotmeleeparams" ] ) )
	{
		self [[ level.bot_builtins[ "clearbotmeleeparams" ] ]]();
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
		player = level.players[ i ];
		
		if ( !player is_bot() )
		{
			continue;
		}
		
		result[ result.size ] = player;
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
		{
			return y - 1;
		}
		else
		{
			return y + 1;
		}
	}
	else
	{
		return y;
	}
}

/*
	Picks a random thing
*/
PickRandom( arr )
{
	if ( !arr.size )
	{
		return undefined;
	}
	
	return arr[ randomint( arr.size ) ];
}

/*
	If is defusing
*/
isDefusing()
{
	return ( isdefined( self.isdefusing ) && self.isdefusing );
}

/*
	If is defusing
*/
isPlanting()
{
	return ( isdefined( self.isplanting ) && self.isplanting );
}

/*
	If is defusing
*/
inLastStand()
{
	return ( isdefined( self.laststand ) && self.laststand );
}

/*
	Is they the flag carrier men?
*/
isFlagCarrier()
{
	return ( isdefined( self.isflagcarrier ) && self.isflagcarrier );
}

/*
	If the site is in use
*/
isInUse()
{
	return ( isdefined( self.inuse ) && self.inuse );
}

/*
	If the player is carrying a bomb
*/
isBombCarrier()
{
	return ( isdefined( self.isbombcarrier ) && self.isbombcarrier );
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
	
	switch ( getdvar( "bot_difficulty" ) )
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
	if ( isstrstart( weap, "gl_" ) || isstrstart( weap, "ft_" ) || isstrstart( weap, "mk_" ) )
	{
		return true;
	}
	
	return false;
}

/*
	Bot will change to angles with speed
*/
bot_lookat( pos, time, vel, doAimPredict )
{
	self notify( "bots_aim_overlap" );
	self endon( "bots_aim_overlap" );
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "spawned_player" );
	level endon ( "game_ended" );
	
	if ( level.gameended || level.inprematchperiod || self BotIsFrozen() || !getdvarint( "bots_play_aim" ) )
	{
		return;
	}
	
	if ( !isdefined( pos ) )
	{
		return;
	}
	
	if ( !isdefined( doAimPredict ) )
	{
		doAimPredict = false;
	}
	
	if ( !isdefined( time ) )
	{
		time = 0.05;
	}
	
	if ( !isdefined( vel ) )
	{
		vel = ( 0, 0, 0 );
	}
	
	steps = int( time * 20 );
	
	if ( steps < 1 )
	{
		steps = 1;
	}
	
	myEye = self geteye(); // get our eye pos
	
	if ( doAimPredict )
	{
		myEye += ( self getvelocity() * 0.05 ) * ( steps - 1 ); // account for our velocity
		
		pos += ( vel * 0.05 ) * ( steps - 1 ); // add the velocity vector
	}
	
	myAngle = self getplayerangles();
	angles = vectortoangles( ( pos - myEye ) - anglestoforward( myAngle ) );
	
	X = angleclamp180( angles[ 0 ] - myAngle[ 0 ] );
	X = X / steps;
	
	Y = angleclamp180( angles[ 1 ] - myAngle[ 1 ] );
	Y = Y / steps;
	
	for ( i = 0; i < steps; i++ )
	{
		myAngle = ( angleclamp180( myAngle[ 0 ] + X ), angleclamp180( myAngle[ 1 ] + Y ), 0 );
		self setplayerangles( myAngle );
		wait 0.05;
	}
}

/*
	Includes altmode weapons
*/
getweaponslistall()
{
	weaps = self getweaponslist();
	
	for ( i = 0; i < weaps.size; i++ )
	{
		weap = weaps[ i ];
		toks = strtok( weap, "_" );
		
		if ( issubstr( weap, "_gl_" ) )
		{
			weaps[ weaps.size ] = "gl_" + toks[ 0 ] + "_mp";
		}
		else if ( issubstr( weap, "_ft_" ) )
		{
			weaps[ weaps.size ] = "ft_" + toks[ 0 ] + "_mp";
		}
		else if ( issubstr( weap, "_mk_" ) )
		{
			weaps[ weaps.size ] = "mk_" + toks[ 0 ] + "_mp";
		}
	}
	
	return weaps;
}

/*
	Returns a valid grenade launcher weapon
*/
getValidTube()
{
	weaps = self getweaponslistall();
	
	for ( i = 0; i < weaps.size; i++ )
	{
		weap = weaps[ i ];
		
		if ( !self getammocount( weap ) )
		{
			continue;
		}
		
		if ( ( issubstr( weap, "gl_" ) && !issubstr( weap, "_gl_" ) ) || weap == "china_lake_mp" )
		{
			return weap;
		}
	}
	
	return undefined;
}

/*
	Taken from iw4 script
*/
waittill_any_timeout( timeOut, string1, string2, string3, string4, string5 )
{
	if ( ( !isdefined( string1 ) || string1 != "death" ) && ( !isdefined( string2 ) || string2 != "death" ) && ( !isdefined( string3 ) || string3 != "death" ) && ( !isdefined( string4 ) || string4 != "death" ) && ( !isdefined( string5 ) || string5 != "death" ) )
	{
		self endon( "death" );
	}
	
	ent = spawnstruct();
	
	if ( isdefined( string1 ) )
	{
		self thread waittill_string( string1, ent );
	}
	
	if ( isdefined( string2 ) )
	{
		self thread waittill_string( string2, ent );
	}
	
	if ( isdefined( string3 ) )
	{
		self thread waittill_string( string3, ent );
	}
	
	if ( isdefined( string4 ) )
	{
		self thread waittill_string( string4, ent );
	}
	
	if ( isdefined( string5 ) )
	{
		self thread waittill_string( string5, ent );
	}
	
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
	Returns a bot to be kicked
*/
getBotToKick()
{
	bots = getBotArray();
	
	if ( !isdefined( bots ) || !isdefined( bots.size ) || bots.size <= 0 || !isdefined( bots[ 0 ] ) )
	{
		return undefined;
	}
	
	tokick = undefined;
	axis = 0;
	allies = 0;
	team = getdvar( "bots_team" );
	
	// count teams
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( !isdefined( bot ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		if ( bot.team == "allies" )
		{
			allies++;
		}
		else if ( bot.team == "axis" )
		{
			axis++;
		}
		else // choose bots that are not on a team first
		{
			return bot;
		}
	}
	
	// search for a bot on the other team
	if ( team == "custom" || team == "axis" )
	{
		team = "allies";
	}
	else if ( team == "autoassign" )
	{
		// get the team with the most bots
		team = "allies";
		
		if ( axis > allies )
		{
			team = "axis";
		}
	}
	else
	{
		team = "axis";
	}
	
	// get the bot on this team with lowest skill
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( !isdefined( bot ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		if ( bot.team != team )
		{
			continue;
		}
		
		tokick = bot;
	}
	
	if ( isdefined( tokick ) )
	{
		return tokick;
	}
	
	// just kick lowest skill
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( !isdefined( bot ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		tokick = bot;
	}
	
	return tokick;
}

/*
	Waits for a host player
*/
bot_wait_for_host()
{
	host = undefined;
	
	while ( !isdefined( level ) || !isdefined( level.players ) )
	{
		wait 0.05;
	}
	
	for ( i = getdvarfloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		host = gethostplayer();
		
		if ( isdefined( host ) )
		{
			break;
		}
		
		wait 0.05;
	}
	
	if ( !isdefined( host ) )
	{
		return;
	}
	
	for ( i = getdvarfloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( isdefined( host.pers[ "team" ] ) )
		{
			break;
		}
		
		wait 0.05;
	}
	
	if ( !isdefined( host.pers[ "team" ] ) )
	{
		return;
	}
	
	for ( i = getdvarfloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis" )
		{
			break;
		}
		
		wait 0.05;
	}
}

/*
	Wrapper for setgoal
*/
SetBotGoal( where, dist )
{
	self setscriptgoal( where, dist );
	waittillframeend;
	self notify( "new_goal" );
}

/*
	Weapper for cleargoal
*/
ClearBotGoal()
{
	self clearscriptgoal();
	waittillframeend;
	self notify( "new_goal" );
}

/*
	Presses the use button
*/
BotPressUse( time )
{
	self pressusebutton( time );
}

/*
	Freeze controls
*/
BotFreezeControls( what )
{
	self freeze_player_controls( what );
}

/*
	Bot is frozen
*/
BotIsFrozen()
{
	return false;
}

/*
	Bot stops moving
*/
botStopMove( what )
{
	self thread botStopMove2( what );
}

/*
	Sets the stance
*/
BotSetStance( what )
{
}

/*
	Freezes bot in place
*/
botStopMove2( what )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self notify( "botStopMove" );
	self endon( "botStopMove" );
	
	if ( !what )
	{
		return;
	}
	
	og = self.origin;
	
	for ( ;; )
	{
		self setvelocity( ( 0, 0, 0 ) );
		self setorigin( og );
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
	dirToTarget = vectornormalize( to - from );
	forward = anglestoforward( dir );
	return vectordot( dirToTarget, forward );
}

/*
	Fixes sd bomb planting
*/
bot_onUsePlantObjectFix( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isfriendlyteam( player.pers[ "team" ] ) )
	{
		level thread bot_bombPlanted( self, player );
		player logstring( "bomb planted: " + self.label );
		
		// disable all bomb zones except this one
		for ( index = 0; index < level.bombzones.size; index++ )
		{
			if ( level.bombzones[ index ] == self )
			{
				continue;
			}
			
			level.bombzones[ index ] maps\mp\gametypes\_gameobjects::disableobject();
		}
		
		thread playsoundonplayers( "mus_sd_planted" + "_" + level.teampostfix[ player.pers[ "team" ] ] );
		// removed plant audio until finalization of assest TODO : new plant sounds when assests are online
		// player playsound( "mpl_sd_bomb_plant" );
		player notify ( "bomb_planted" );
		
		level thread maps\mp\_popups::displayteammessagetoall( &"MP_EXPLOSIVES_PLANTED_BY", player );
		
		if ( isdefined( player.pers[ "plants" ] ) )
		{
			player.pers[ "plants" ]++;
			player.plants = player.pers[ "plants" ];
		}
		
		player maps\mp\_medals::saboteur();
		player maps\mp\gametypes\_persistence::stataddwithgametype( "PLANTS", 1 );
		
		maps\mp\gametypes\_globallogic_audio::leaderdialog( "bomb_planted" );
		
		maps\mp\gametypes\_globallogic_score::giveplayerscore( "plant", player );
		// player thread [[ level.onxpevent ]]( "plant" );
	}
}

/*
	Fixes sd bomb planting
*/
bot_bombPlanted( destroyedObj, player )
{
	maps\mp\gametypes\_globallogic_utils::pausetimer();
	level.bombplanted = true;
	
	destroyedObj.visuals[ 0 ] thread maps\mp\gametypes\_globallogic_utils::playtickingsound( "mpl_sab_ui_suitcasebomb_timer" );
	// Play suspense music
	level thread maps\mp\gametypes\sd::bombplantedmusicdelay();
	
	// thread maps\mp\gametypes\_globallogic_audio::actionmusicset();
	
	level.tickingobject = destroyedObj.visuals[ 0 ];
	
	level.timelimitoverride = true;
	setgameendtime( int( gettime() + ( level.bombtimer * 1000 ) ) );
	setmatchflag( "bomb_timer", 1 );
	
	if ( !level.multibomb )
	{
		level.sdbomb maps\mp\gametypes\_gameobjects::allowcarry( "none" );
		level.sdbomb maps\mp\gametypes\_gameobjects::setvisibleteam( "none" );
		level.sdbomb maps\mp\gametypes\_gameobjects::setdropped();
		level.sdbombmodel = level.sdbomb.visuals[ 0 ];
	}
	else
	{
	
		for ( index = 0; index < level.players.size; index++ )
		{
			if ( isdefined( level.players[ index ].carryicon ) )
			{
				level.players[ index ].carryicon destroyelem();
			}
		}
		
		trace = bullettrace( player.origin + ( 0, 0, 20 ), player.origin - ( 0, 0, 2000 ), false, player );
		
		tempAngle = randomfloat( 360 );
		forward = ( cos( tempAngle ), sin( tempAngle ), 0 );
		forward = vectornormalize( forward - vector_scale( trace[ "normal" ], vectordot( forward, trace[ "normal" ] ) ) );
		dropAngles = vectortoangles( forward );
		
		level.sdbombmodel = spawn( "script_model", trace[ "position" ] );
		level.sdbombmodel.angles = dropAngles;
		level.sdbombmodel setmodel( "prop_suitcase_bomb" );
	}
	
	destroyedObj maps\mp\gametypes\_gameobjects::allowuse( "none" );
	destroyedObj maps\mp\gametypes\_gameobjects::setvisibleteam( "none" );
	/*
	    destroyedObj maps\mp\gametypes\_gameobjects::set2dicon( "friendly", undefined );
	    destroyedObj maps\mp\gametypes\_gameobjects::set2dicon( "enemy", undefined );
	    destroyedObj maps\mp\gametypes\_gameobjects::set3dicon( "friendly", undefined );
	    destroyedObj maps\mp\gametypes\_gameobjects::set3dicon( "enemy", undefined );
	*/
	label = destroyedObj maps\mp\gametypes\_gameobjects::getlabel();
	
	// create a new object to defuse with.
	trigger = destroyedObj.bombdefusetrig;
	trigger.origin = level.sdbombmodel.origin;
	visuals = [];
	defuseObject = maps\mp\gametypes\_gameobjects::createuseobject( game[ "defenders" ], trigger, visuals, ( 0, 0, 32 ) );
	defuseObject maps\mp\gametypes\_gameobjects::allowuse( "friendly" );
	defuseObject maps\mp\gametypes\_gameobjects::setusetime( level.defusetime );
	defuseObject maps\mp\gametypes\_gameobjects::setusetext( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject maps\mp\gametypes\_gameobjects::setusehinttext( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject maps\mp\gametypes\_gameobjects::setvisibleteam( "any" );
	defuseObject maps\mp\gametypes\_gameobjects::set2dicon( "friendly", "compass_waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set2dicon( "enemy", "compass_waypoint_defend" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3dicon( "friendly", "waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3dicon( "enemy", "waypoint_defend" + label );
	defuseObject.label = label;
	defuseObject.onbeginuse = maps\mp\gametypes\sd::onbeginuse;
	defuseObject.onenduse = maps\mp\gametypes\sd::onenduse;
	defuseObject.onuse = maps\mp\gametypes\sd::onusedefuseobject;
	defuseObject.useweapon = "briefcase_bomb_defuse_mp";
	
	level.defuseobject = defuseObject; // every cod...
	
	player.isbombcarrier = false;
	
	maps\mp\gametypes\sd::bombtimerwait();
	setmatchflag( "bomb_timer", 0 );
	
	destroyedObj.visuals[ 0 ] maps\mp\gametypes\_globallogic_utils::stoptickingsound();
	
	if ( level.gameended || level.bombdefused )
	{
		return;
	}
	
	level.bombexploded = true;
	
	
	explosionOrigin = level.sdbombmodel.origin + ( 0, 0, 12 );
	level.sdbombmodel hide();
	
	if ( isdefined( player ) )
	{
		destroyedObj.visuals[ 0 ] radiusdamage( explosionOrigin, 512, 200, 20, player, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
		level thread maps\mp\_popups::displayteammessagetoall( &"MP_EXPLOSIVES_BLOWUP_BY", player );
		player maps\mp\_medals::bomber();
		player maps\mp\gametypes\_persistence::stataddwithgametype( "DESTRUCTIONS", 1 );
	}
	else
	{
		destroyedObj.visuals[ 0 ] radiusdamage( explosionOrigin, 512, 200, 20, undefined, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
	}
	
	rot = randomfloat( 360 );
	explosionEffect = spawnfx( level._effect[ "bombexplosion" ], explosionOrigin + ( 0, 0, 50 ), ( 0, 0, 1 ), ( cos( rot ), sin( rot ), 0 ) );
	triggerfx( explosionEffect );
	
	thread playsoundinspace( "mpl_sd_exp_suitcase_bomb_main", explosionOrigin );
	// thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "SILENT", "both" );
	
	if ( isdefined( destroyedObj.exploderindex ) )
	{
		exploder( destroyedObj.exploderindex );
	}
	
	for ( index = 0; index < level.bombzones.size; index++ )
	{
		level.bombzones[ index ] maps\mp\gametypes\_gameobjects::disableobject();
	}
	
	defuseObject maps\mp\gametypes\_gameobjects::disableobject();
	
	setgameendtime( 0 );
	
	wait 3;
	
	maps\mp\gametypes\sd::sd_endgame( game[ "attackers" ], game[ "strings" ][ "target_destroyed" ] );
}
