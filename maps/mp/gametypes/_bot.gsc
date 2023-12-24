/*
	_bot
	Author: INeedGames
	Date: 12/20/2020
	The entry point and manager of the bots.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	Entry point to the bots
*/
init()
{
	level.bw_version = "1.1.1";

	level.bot_offline = false;

	if ( getdvar( "bots_main" ) == "" )
	{
		setdvar( "bots_main", true );
	}

	if ( !getdvarint( "bots_main" ) )
	{
		return;
	}

	if ( !wait_for_builtins() )
	{
		println( "FATAL: NO BUILT-INS FOR BOTS" );
	}

	if ( getdvar( "bots_main_waitForHostTime" ) == "" )
	{
		setdvar( "bots_main_waitForHostTime", 10.0 ); // how long to wait to wait for the host player
	}

	if ( getdvar( "bots_main_kickBotsAtEnd" ) == "" )
	{
		setdvar( "bots_main_kickBotsAtEnd", false ); // kicks the bots at game end
	}

	if ( getdvar( "bots_manage_add" ) == "" )
	{
		setdvar( "bots_manage_add", 0 ); // amount of bots to add to the game
	}

	if ( getdvar( "bots_manage_fill" ) == "" )
	{
		setdvar( "bots_manage_fill", 0 ); // amount of bots to maintain
	}

	if ( getdvar( "bots_manage_fill_spec" ) == "" )
	{
		setdvar( "bots_manage_fill_spec", true ); // to count for fill if player is on spec team
	}

	if ( getdvar( "bots_manage_fill_mode" ) == "" )
	{
		setdvar( "bots_manage_fill_mode", 0 ); // fill mode, 0 adds everyone, 1 just bots, 2 maintains at maps, 3 is 2 with 1
	}

	if ( getdvar( "bots_manage_fill_kick" ) == "" )
	{
		setdvar( "bots_manage_fill_kick", false ); // kick bots if too many
	}

	if ( getdvar( "bots_skill" ) == "" ) // alias for bot_difficulty
	{
		setdvar( "bots_skill", "" );
	}

	if ( getdvar( "bots_team" ) == "" )
	{
		setdvar( "bots_team", "autoassign" ); // which team for bots to join
	}

	if ( getdvar( "bots_team_amount" ) == "" )
	{
		setdvar( "bots_team_amount", 0 ); // amount of bots on axis team
	}

	if ( getdvar( "bots_team_force" ) == "" )
	{
		setdvar( "bots_team_force", false ); // force bots on team
	}

	if ( getdvar( "bots_team_mode" ) == "" )
	{
		setdvar( "bots_team_mode", 0 ); // counts just bots when 1
	}

	if ( getdvar( "bots_loadout_reasonable" ) == "" ) // filter out the bad 'guns' and perks
	{
		setdvar( "bots_loadout_reasonable", false );
	}

	if ( getdvar( "bots_loadout_allow_op" ) == "" ) // allows jug, marty and laststand
	{
		setdvar( "bots_loadout_allow_op", true );
	}

	if ( getdvar( "bots_loadout_rank" ) == "" ) // what rank the bots should be around, -1 is around the players, 0 is all random
	{
		setdvar( "bots_loadout_rank", -1 );
	}

	if ( getdvar( "bots_loadout_codpoints" ) == "" ) // how much cod points a bot should have, -1 is around the players, 0 is all random
	{
		setdvar( "bots_loadout_codpoints", -1 );
	}

	if ( getdvar( "bots_loadout_prestige" ) == "" ) // what pretige the bots will be, -1 is the players, -2 is random
	{
		setdvar( "bots_loadout_prestige", -1 );
	}

	if ( getdvar( "bots_play_target_other" ) == "" ) // bot target non play ents (vehicles)
	{
		setdvar( "bots_play_target_other", true );
	}

	if ( getdvar( "bots_play_killstreak" ) == "" ) // bot use killstreaks
	{
		setdvar( "bots_play_killstreak", true );
	}

	if ( getdvar( "bots_play_nade" ) == "" ) // bots grenade
	{
		setdvar( "bots_play_nade", true );
	}

	if ( getdvar( "bots_play_knife" ) == "" ) // bots knife
	{
		setdvar( "bots_play_knife", true );
	}

	if ( getdvar( "bots_play_fire" ) == "" ) // bots fire
	{
		setdvar( "bots_play_fire", true );
	}

	if ( getdvar( "bots_play_move" ) == "" ) // bots move
	{
		setdvar( "bots_play_move", true );
	}

	if ( getdvar( "bots_play_take_carepackages" ) == "" ) // bots take carepackages
	{
		setdvar( "bots_play_take_carepackages", true );
	}

	if ( getdvar( "bots_play_obj" ) == "" ) // bots play the obj
	{
		setdvar( "bots_play_obj", true );
	}

	if ( getdvar( "bots_play_camp" ) == "" ) // bots camp and follow
	{
		setdvar( "bots_play_camp", true );
	}

	if ( getdvar( "bots_play_aim" ) == "" )
	{
		setdvar( "bots_play_aim", true );
	}

	if ( getdvar( "bots_play_jumpdrop" ) == "" ) // bots jump and dropshot
	{
		setdvar( "bots_play_jumpdrop", true );
	}

	level.bots = [];
	level.bot_decoys = [];
	level.bot_planes = [];

	if ( !isdefined( game[ "botWarfare" ] ) )
	{
		game[ "botWarfare" ] = true;
	}

	thread fixGamemodes();
	thread onPlayerConnect();
	thread bot_watch_planes();

	thread handleBots();

	thread doNonDediBots();
}

/*
	Thread when any player connects. Starts the threads needed.
*/
onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );

		player thread watch_shoot();
		player thread watch_grenade();
		player thread connected();
	}
}

/*
	Starts the threads for bots.
*/
handleBots()
{
	thread diffBots();
	thread teamBots();
	addBots();

	while ( !level.intermission )
	{
		wait 0.05;
	}

	setdvar( "bots_manage_add", getBotArray().size );

	if ( !getdvarint( "bots_main_kickBotsAtEnd" ) )
	{
		return;
	}

	bots = getBotArray();

	for ( i = 0; i < bots.size; i++ )
	{
		kick( bots[ i ] getentitynumber() );
	}
}

/*
	When a bot disconnects.
*/
onDisconnect()
{
	self waittill( "disconnect" );

	level.bots = array_remove( level.bots, self );
}

/*
	Whena	player connects
*/
connected()
{
	self endon( "disconnect" );

	if ( !self is_bot() )
	{
		return;
	}

	self thread maps\mp\bots\_bot_script::connected();

	level.bots[ level.bots.size ] = self;
	self thread onDisconnect();

	level notify( "bot_connected", self );

	self thread watchBotDebugEvent();
}

/*
	DEBUG
*/
watchBotDebugEvent()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "bot_event", msg, str, b, c, d, e, f, g );

		if ( getdvarint( "bots_main_debug" ) >= 2 )
		{
			big_str = "Bot Warfare debug: " + self.name + ": " + msg + ": " + str;

			if ( isdefined( b ) && isstring( b ) )
			{
				big_str += ": " + b;
			}

			if ( isdefined( c ) && isstring( c ) )
			{
				big_str += ": " + c;
			}

			if ( isdefined( d ) && isstring( d ) )
			{
				big_str += ": " + d;
			}

			if ( isdefined( e ) && isstring( e ) )
			{
				big_str += ": " + e;
			}

			if ( isdefined( f ) && isstring( f ) )
			{
				big_str += ": " + f;
			}

			if ( isdefined( g ) && isstring( g ) )
			{
				big_str += ": " + g;
			}

			BotBuiltinPrintConsole( big_str );
		}
		else if ( msg == "debug" && getdvarint( "bots_main_debug" ) )
		{
			BotBuiltinPrintConsole( "Bot Warfare debug: " + self.name + ": " + str );
		}
	}
}

/*
	Handles the diff of the bots
*/
diffBots()
{
	for ( ;; )
	{
		wait 1.5;

		// we dont use 'bots_skill' so that we can still use the .menu dvar

		if ( getdvar( "bots_skill" ) != "" )
		{
			setdvar( "bot_difficulty", getdvar( "bots_skill" ) );
			setdvar( "bots_skill", "" );
		}

		bot_set_difficulty( getdvar( #"bot_difficulty" ) );
	}
}

/*
	Setup bot dvars for non dedicated clients
*/
doNonDediBots()
{
	if ( !getdvarint( #"xblive_basictraining" ) )
	{
		return;
	}

	if ( isdefined( game[ "bots_spawned" ] ) )
	{
		return;
	}

	game[ "bots_spawned" ] = true;

	if ( getdvar( "bot_enemies_extra" ) == "" )
	{
		setdvar( "bot_enemies_extra", 0 );
	}

	if ( getdvar( "bot_friends_extra" ) == "" )
	{
		setdvar( "bot_friends_extra", 0 );
	}

	bot_friends = getdvarint( #"bot_friends" );
	bot_enemies = getdvarint( #"bot_enemies" );

	bot_enemies += getdvarint( "bot_enemies_extra" );
	bot_friends += getdvarint( "bot_friends_extra" );

	bot_wait_for_host();
	host = gethostplayer();

	team = "allies";

	if ( isdefined( host ) && isdefined( host.pers[ "team" ] ) && ( host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis" ) )
	{
		team = host.pers[ "team" ];
	}

	setdvar( "bots_manage_add", bot_enemies + bot_friends - 1 );
	setdvar( "bots_manage_fill", bot_enemies + bot_friends );
	setdvar( "bots_manage_fill_mode", 0 );
	setdvar( "bots_manage_fill_kick", true );
	setdvar( "bots_manage_fill_spec", false );

	setdvar( "bots_team", "custom" );

	if ( team == "axis" )
	{
		setdvar( "bots_team_amount", bot_friends );
	}
	else
	{
		setdvar( "bots_team_amount", bot_enemies );
	}

	setdvar( "bots_team_force", true );
	setdvar( "bots_team_mode", 0 );
}

/*
	Sets the difficulty of the bots
*/
bot_set_difficulty( difficulty )
{
	if ( difficulty == "fu" )
	{
		setdvar( "sv_botMinDeathTime",		"250" );
		setdvar( "sv_botMaxDeathTime",		"500" );
		setdvar( "sv_botMinFireTime",		"100" );
		setdvar( "sv_botMaxFireTime",		"300" );
		setdvar( "sv_botYawSpeed",			"14" );
		setdvar( "sv_botYawSpeedAds",		"14" );
		setdvar( "sv_botPitchUp",			"-5" );
		setdvar( "sv_botPitchDown",			"10" );
		setdvar( "sv_botFov",				"160" );
		setdvar( "sv_botMinAdsTime",		"3000" );
		setdvar( "sv_botMaxAdsTime",		"5000" );
		setdvar( "sv_botMinCrouchTime",		"100" );
		setdvar( "sv_botMaxCrouchTime",		"400" );
		setdvar( "sv_botTargetLeadBias",	"2" );
		setdvar( "sv_botMinReactionTime",	"30" );
		setdvar( "sv_botMaxReactionTime",	"100" );
		setdvar( "sv_botStrafeChance",		"1" );
		setdvar( "sv_botMinStrafeTime",		"3000" );
		setdvar( "sv_botMaxStrafeTime",		"6000" );
		setdvar( "scr_help_dist",			"512" );
		setdvar( "sv_botAllowGrenades",		"1"	);
		setdvar( "sv_botMinGrenadeTime",	"1500" );
		setdvar( "sv_botMaxGrenadeTime",	"4000" );
		setdvar( "sv_botSprintDistance",	"512"	);
		setdvar( "sv_botMeleeDist",			"80" );
	}
	else if ( difficulty == "hard" )
	{
		setdvar( "sv_botMinDeathTime",		"250" );
		setdvar( "sv_botMaxDeathTime",		"500" );
		setdvar( "sv_botMinFireTime",		"400" );
		setdvar( "sv_botMaxFireTime",		"600" );
		setdvar( "sv_botYawSpeed",			"8" );
		setdvar( "sv_botYawSpeedAds",		"10" );
		setdvar( "sv_botPitchUp",			"-5" );
		setdvar( "sv_botPitchDown",			"10" );
		setdvar( "sv_botFov",				"100" );
		setdvar( "sv_botMinAdsTime",		"3000" );
		setdvar( "sv_botMaxAdsTime",		"5000" );
		setdvar( "sv_botMinCrouchTime",		"100" );
		setdvar( "sv_botMaxCrouchTime",		"400" );
		setdvar( "sv_botTargetLeadBias",	"2" );
		setdvar( "sv_botMinReactionTime",	"400" );
		setdvar( "sv_botMaxReactionTime",	"700" );
		setdvar( "sv_botStrafeChance",		"0.9" );
		setdvar( "sv_botMinStrafeTime",		"3000" );
		setdvar( "sv_botMaxStrafeTime",		"6000" );
		setdvar( "scr_help_dist",			"384" );
		setdvar( "sv_botAllowGrenades",		"1"	);
		setdvar( "sv_botMinGrenadeTime",	"1500" );
		setdvar( "sv_botMaxGrenadeTime",	"4000" );
		setdvar( "sv_botSprintDistance",	"512"	);
		setdvar( "sv_botMeleeDist",			"80" );
	}
	else if ( difficulty == "easy" )
	{
		setdvar( "sv_botMinDeathTime",		"1000" );
		setdvar( "sv_botMaxDeathTime",		"2000" );
		setdvar( "sv_botMinFireTime",		"900" );
		setdvar( "sv_botMaxFireTime",		"1000" );
		setdvar( "sv_botYawSpeed",			"2" );
		setdvar( "sv_botYawSpeedAds",		"2.5" );
		setdvar( "sv_botPitchUp",			"-20" );
		setdvar( "sv_botPitchDown",			"40" );
		setdvar( "sv_botFov",				"50" );
		setdvar( "sv_botMinAdsTime",		"3000" );
		setdvar( "sv_botMaxAdsTime",		"5000" );
		setdvar( "sv_botMinCrouchTime",		"4000" );
		setdvar( "sv_botMaxCrouchTime",		"6000" );
		setdvar( "sv_botTargetLeadBias",	"8" );
		setdvar( "sv_botMinReactionTime",	"1200" );
		setdvar( "sv_botMaxReactionTime",	"1600" );
		setdvar( "sv_botStrafeChance",		"0.1" );
		setdvar( "sv_botMinStrafeTime",		"3000" );
		setdvar( "sv_botMaxStrafeTime",		"6000" );
		setdvar( "scr_help_dist",			"256" );
		setdvar( "sv_botAllowGrenades",		"0"	);
		setdvar( "sv_botSprintDistance",	"1024"	);
		setdvar( "sv_botMeleeDist",			"40" );
	}
	else // 'normal' difficulty
	{
		if ( difficulty != "normal" )
		{
			return;
		}

		setdvar( "sv_botMinDeathTime",		"500" );
		setdvar( "sv_botMaxDeathTime",		"1000" );
		setdvar( "sv_botMinFireTime",		"600" );
		setdvar( "sv_botMaxFireTime",		"800" );
		setdvar( "sv_botYawSpeed",			"4" );
		setdvar( "sv_botYawSpeedAds",		"5" );
		setdvar( "sv_botPitchUp",			"-10" );
		setdvar( "sv_botPitchDown",			"20" );
		setdvar( "sv_botFov",				"70" );
		setdvar( "sv_botMinAdsTime",		"3000" );
		setdvar( "sv_botMaxAdsTime",		"5000" );
		setdvar( "sv_botMinCrouchTime",		"2000" );
		setdvar( "sv_botMaxCrouchTime",		"4000" );
		setdvar( "sv_botTargetLeadBias",	"4" );
		setdvar( "sv_botMinReactionTime",	"800" );
		setdvar( "sv_botMaxReactionTime",	"1200" );
		setdvar( "sv_botStrafeChance",		"0.6" );
		setdvar( "sv_botMinStrafeTime",		"3000" );
		setdvar( "sv_botMaxStrafeTime",		"6000" );
		setdvar( "scr_help_dist",			"256" );
		setdvar( "sv_botAllowGrenades",		"1"	);
		setdvar( "sv_botMinGrenadeTime",	"1500" );
		setdvar( "sv_botMaxGrenadeTime",	"4000" );
		setdvar( "sv_botSprintDistance",	"512"	);
		setdvar( "sv_botMeleeDist",			"80" );
		difficulty = "normal";
	}

	if ( level.gametype == "oic" && difficulty == "fu" )
	{
		setdvar( "sv_botMinReactionTime",		"400" );
		setdvar( "sv_botMaxReactionTime",		"500" );
		setdvar( "sv_botMinAdsTime",		"1000" );
		setdvar( "sv_botMaxAdsTime",		"2000" );
	}

	if ( level.gametype == "oic" && ( difficulty == "hard" || difficulty == "fu" ) )
	{
		setdvar( "sv_botSprintDistance",	"256" );
	}

	if ( !getdvarint( "bots_play_nade" ) )
	{
		setdvar( "sv_botAllowGrenades",		"0"	);
	}

	if ( !getdvarint( "bots_play_aim" ) )
	{
		setdvar( "sv_botYawSpeed", "0" );
		setdvar( "sv_botYawSpeedAds", "0" );
		setdvar( "sv_botPitchUp", "0" );
		setdvar( "sv_botPitchDown", "0" );
	}

	setdvar( "bot_difficulty", difficulty );
	setdvar( "scr_bot_difficulty", difficulty );
	setdvar( "splitscreen_botDifficulty", difficulty );
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots_loop()
{
	teamAmount = getdvarint( "bots_team_amount" );
	toTeam = getdvar( "bots_team" );

	alliesbots = 0;
	alliesplayers = 0;
	axisbots = 0;
	axisplayers = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[ i ];

		if ( !isdefined( player.pers[ "team" ] ) )
		{
			continue;
		}

		if ( player is_bot() )
		{
			if ( player.pers[ "team" ] == "allies" )
			{
				alliesbots++;
			}
			else if ( player.pers[ "team" ] == "axis" )
			{
				axisbots++;
			}
		}
		else
		{
			if ( player.pers[ "team" ] == "allies" )
			{
				alliesplayers++;
			}
			else if ( player.pers[ "team" ] == "axis" )
			{
				axisplayers++;
			}
		}
	}

	allies = alliesbots;
	axis = axisbots;

	if ( !getdvarint( "bots_team_mode" ) )
	{
		allies += alliesplayers;
		axis += axisplayers;
	}

	if ( toTeam != "custom" )
	{
		if ( getdvarint( "bots_team_force" ) )
		{
			if ( toTeam == "autoassign" )
			{
				if ( abs( axis - allies ) > 1 )
				{
					toTeam = "axis";

					if ( axis > allies )
					{
						toTeam = "allies";
					}
				}
			}

			if ( toTeam != "autoassign" )
			{
				playercount = level.players.size;

				for ( i = 0; i < playercount; i++ )
				{
					player = level.players[ i ];

					if ( !isdefined( player.pers[ "team" ] ) )
					{
						continue;
					}

					if ( !player is_bot() )
					{
						continue;
					}

					if ( player.pers[ "team" ] == toTeam )
					{
						continue;
					}

					if ( toTeam == "allies" )
					{
						player thread [[ level.allies ]]();
					}
					else if ( toTeam == "axis" )
					{
						player thread [[ level.axis ]]();
					}
					else
					{
						player thread [[ level.spectator ]]();
					}

					break;
				}
			}
		}
	}
	else
	{
		playercount = level.players.size;

		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];

			if ( !isdefined( player.pers[ "team" ] ) )
			{
				continue;
			}

			if ( !player is_bot() )
			{
				continue;
			}

			if ( player.pers[ "team" ] == "axis" )
			{
				if ( axis > teamAmount )
				{
					player thread [[ level.allies ]]();
					break;
				}
			}
			else
			{
				if ( axis < teamAmount )
				{
					player thread [[ level.axis ]]();
					break;
				}
				else if ( player.pers[ "team" ] != "allies" )
				{
					player thread [[ level.allies ]]();
					break;
				}
			}
		}
	}
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots()
{
	for ( ;; )
	{
		wait 1.5;
		teamBots_loop();
	}
}

/*
	Loop
*/
addBots_loop()
{
	botsToAdd = getdvarint( "bots_manage_add" );

	if ( botsToAdd > 0 )
	{
		setdvar( "bots_manage_add", 0 );

		if ( botsToAdd > 64 )
		{
			botsToAdd = 64;
		}

		for ( ; botsToAdd > 0; botsToAdd-- )
		{
			level add_bot();
			wait 0.25;
		}
	}

	fillMode = getdvarint( "bots_manage_fill_mode" );

	if ( fillMode == 2 || fillMode == 3 )
	{
		setdvar( "bots_manage_fill", getGoodMapAmount() );
	}

	fillAmount = getdvarint( "bots_manage_fill" );

	players = 0;
	bots = 0;
	spec = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[ i ];

		if ( player isdemoclient() )
		{
			continue;
		}

		if ( player is_bot() )
		{
			bots++;
		}
		else if ( !isdefined( player.pers[ "team" ] ) || ( player.pers[ "team" ] != "axis" && player.pers[ "team" ] != "allies" ) )
		{
			spec++;
		}
		else
		{
			players++;
		}
	}

	if ( fillMode == 4 )
	{
		axisplayers = 0;
		alliesplayers = 0;

		playercount = level.players.size;

		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];

			if ( player is_bot() )
			{
				continue;
			}

			if ( !isdefined( player.pers[ "team" ] ) )
			{
				continue;
			}

			if ( player.pers[ "team" ] == "axis" )
			{
				axisplayers++;
			}
			else if ( player.pers[ "team" ] == "allies" )
			{
				alliesplayers++;
			}
		}

		result = fillAmount - abs( axisplayers - alliesplayers ) + bots;

		if ( players == 0 )
		{
			if ( bots < fillAmount )
			{
				result = fillAmount - 1;
			}
			else if ( bots > fillAmount )
			{
				result = fillAmount + 1;
			}
			else
			{
				result = fillAmount;
			}
		}

		bots = result;
	}

	if ( !randomint( 999 ) )
	{
		setdvar( "testclients_doreload", true );
		wait 0.1;
		setdvar( "testclients_doreload", false );
		doExtraCheck();
	}

	amount = bots;

	if ( fillMode == 0 || fillMode == 2 )
	{
		amount += players;
	}

	if ( getdvarint( "bots_manage_fill_spec" ) )
	{
		amount += spec;
	}

	if ( amount < fillAmount )
	{
		setdvar( "bots_manage_add", 1 );
	}
	else if ( amount > fillAmount && getdvarint( "bots_manage_fill_kick" ) )
	{
		tempBot = getBotToKick();

		if ( isdefined( tempBot ) )
		{
			kick( tempBot getentitynumber(), "EXE_PLAYERKICKED" );
		}
	}
}

/*
	A server thread for monitoring all bot's in game. Will add and kick bots according to server settings.
*/
addBots()
{
	level endon ( "game_ended" );

	bot_wait_for_host();

	for ( ;; )
	{
		wait 1.5;

		addBots_loop();
	}
}

/*
	Adds a bot to the game.
*/
add_bot()
{
	bot = addtestclient();

	if ( isdefined( bot ) )
	{
		bot.pers[ "isBot" ] = true;
		bot.pers[ "isBotWarfare" ] = true;
		bot thread maps\mp\bots\_bot_script::added();
	}
}

/*
	Gives the bot loadout
*/
bot_give_loadout()
{
	self maps\mp\bots\_bot_loadout::bot_give_loadout();
}

/*
	Fired when the bot is damaged
*/
bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
	self maps\mp\bots\_bot_script::bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc );
}

/*
	Bot is idle
*/
bot_is_idle()
{
	if ( !isdefined( self ) )
	{
		return false;
	}

	if ( !isalive( self ) )
	{
		return false;
	}

	if ( !self is_bot() )
	{
		return false;
	}

	if ( self inLastStand() )
	{
		return false;
	}

	if ( self hasscriptgoal() )
	{
		return false;
	}

	if ( isdefined( self getthreat() ) )
	{
		return false;
	}

	if ( self isremotecontrolling() || self.bot_lock_goal )
	{
		return false;
	}

	if ( self usebuttonpressed() )
	{
		return false;
	}

	if ( self isPlanting() )
	{
		return false;
	}

	if ( self isDefusing() )
	{
		return false;
	}

	return true;
}

/*
	Watch all players grenades
*/
watch_grenade()
{
	self endon( "disconnect" );

	self.bot_scrambled = false;

	for ( ;; )
	{
		self waittill( "grenade_fire", g, name );

		if ( !isdefined( g ) )
		{
			continue;
		}

		if ( name == "scrambler_mp" )
		{
			g thread watch_scrambler();
		}
		else if ( name == "nightingale_mp" )
		{
			self thread watch_decoy( g );
		}
	}
}

/*
	Watch the decoy grenade
*/
watch_decoy( g )
{
	g.team = self.team;

	level.bot_decoys[ level.bot_decoys.size ] = g;

	g waittill( "death" );

	for ( entry = 0; entry < level.bot_decoys.size; entry++ )
	{
		if ( level.bot_decoys[ entry ] == g )
		{
			while ( entry < level.bot_decoys.size - 1 )
			{
				level.bot_decoys[ entry ] = level.bot_decoys[ entry + 1 ];
				entry++;
			}

			level.bot_decoys[ entry ] = undefined;
			break;
		}
	}
}

/*
	attach a trigger to the scrambler
*/
watch_scrambler()
{
	trig = spawn( "trigger_radius", self.origin + ( 0, 0, -1000 ), 0, 1000, 2000 );

	self scramble_nearby( trig );

	trig delete ();
}

/*
	Watch when players enter the scrambler trigger
*/
scramble_nearby( trig )
{
	self endon( "death" );
	self endon( "hacked" );

	while ( !isdefined( self.owner ) || !isdefined( self.owner.team ) )
	{
		wait 0.05;
	}

	self.team = self.owner.team;

	for ( ;; )
	{
		trig waittill( "trigger", player );

		if ( !isdefined( player ) || !isdefined( player.team ) )
		{
			continue;
		}

		if ( self maps\mp\gametypes\_weaponobjects::isstunned() )
		{
			continue;
		}

		if ( isdefined( self.owner ) && player == self.owner )
		{
			continue;
		}

		if ( level.teambased && self.team == player.team )
		{
			continue;
		}

		player thread scramble_player();
	}
}

/*
	Scramble this player
*/
scramble_player()
{
	self notify( "scramble_nearby" );
	self endon( "scramble_nearby" );

	self.bot_scrambled = true;
	wait 0.1;

	if ( isdefined( self ) )
	{
		self.bot_scrambled = false;
	}
}

/*
	Watch when a player shoots
*/
watch_shoot()
{
	self endon( "disconnect" );

	self.bot_firing = false;

	for ( ;; )
	{
		self waittill( "weapon_fired" );
		self thread doFiringThread();
	}
}

/*
	When a player fires
*/
doFiringThread()
{
	self endon( "disconnect" );
	self endon( "weapon_fired" );

	self.bot_firing = true;
	wait 1;
	self.bot_firing = false;
}

/*
	Watches the planes
*/
bot_watch_planes_loop()
{
	ents = getentarray( "script_model", "classname" );

	for ( i = 0; i < ents.size; i++ )
	{
		ent = ents[ i ];

		if ( isdefined( ent.bot_plane ) )
		{
			continue;
		}

		if ( ent.model != level.spyplanemodel )
		{
			continue;
		}

		thread watch_plane( ent );
	}
}

/*
	Watches the planes
*/
bot_watch_planes()
{
	for ( ;; )
	{
		level waittill( "uav_update" );

		bot_watch_planes_loop();
	}
}

/*
	Watches the plane
*/
watch_plane( ent )
{
	ent.bot_plane = true;

	level.bot_planes[ level.bot_planes.size ] = ent;

	ent waittill_any( "death", "delete", "leaving" );

	for ( entry = 0; entry < level.bot_planes.size; entry++ )
	{
		if ( level.bot_planes[ entry ] == ent )
		{
			while ( entry < level.bot_planes.size - 1 )
			{
				level.bot_planes[ entry ] = level.bot_planes[ entry + 1 ];
				entry++;
			}

			level.bot_planes[ entry ] = undefined;
			break;
		}
	}
}

/*
	Fix xp in sd
*/
bot_killBoost()
{
	return false;
}

/*
	Fixes sd
*/
fixGamemodes()
{
	for ( i = 0; i < 19; i++ )
	{
		if ( isdefined( level.bombzones ) && level.gametype == "sd" )
		{
			level.iskillboosting = ::bot_killBoost;

			for ( i = 0; i < level.bombzones.size; i++ )
			{
				level.bombzones[ i ].onuse = ::bot_onUsePlantObjectFix;
			}

			break;
		}

		wait 0.05;
	}
}
