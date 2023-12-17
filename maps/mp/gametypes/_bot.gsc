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
	level.bw_VERSION = "1.1.1";

	level.bot_offline = false;

	if ( getDvar( "bots_main" ) == "" )
		setDvar( "bots_main", true );

	if ( !getDvarInt( "bots_main" ) )
		return;

	if ( !wait_for_builtins() )
		PrintLn( "FATAL: NO BUILT-INS FOR BOTS" );

	if ( getDvar( "bots_main_waitForHostTime" ) == "" )
		setDvar( "bots_main_waitForHostTime", 10.0 ); //how long to wait to wait for the host player

	if ( getDvar( "bots_main_kickBotsAtEnd" ) == "" )
		setDvar( "bots_main_kickBotsAtEnd", false ); //kicks the bots at game end

	if ( getDvar( "bots_manage_add" ) == "" )
		setDvar( "bots_manage_add", 0 ); //amount of bots to add to the game

	if ( getDvar( "bots_manage_fill" ) == "" )
		setDvar( "bots_manage_fill", 0 ); //amount of bots to maintain

	if ( getDvar( "bots_manage_fill_spec" ) == "" )
		setDvar( "bots_manage_fill_spec", true ); //to count for fill if player is on spec team

	if ( getDvar( "bots_manage_fill_mode" ) == "" )
		setDvar( "bots_manage_fill_mode", 0 ); //fill mode, 0 adds everyone, 1 just bots, 2 maintains at maps, 3 is 2 with 1

	if ( getDvar( "bots_manage_fill_kick" ) == "" )
		setDvar( "bots_manage_fill_kick", false ); //kick bots if too many

	if ( getDvar( "bots_skill" ) == "" ) // alias for bot_difficulty
		setDvar( "bots_skill", "" );

	if ( getDvar( "bots_team" ) == "" )
		setDvar( "bots_team", "autoassign" ); //which team for bots to join

	if ( getDvar( "bots_team_amount" ) == "" )
		setDvar( "bots_team_amount", 0 ); //amount of bots on axis team

	if ( getDvar( "bots_team_force" ) == "" )
		setDvar( "bots_team_force", false ); //force bots on team

	if ( getDvar( "bots_team_mode" ) == "" )
		setDvar( "bots_team_mode", 0 ); //counts just bots when 1

	if ( getDvar( "bots_loadout_reasonable" ) == "" ) //filter out the bad 'guns' and perks
		setDvar( "bots_loadout_reasonable", false );

	if ( getDvar( "bots_loadout_allow_op" ) == "" ) //allows jug, marty and laststand
		setDvar( "bots_loadout_allow_op", true );

	if ( getDvar( "bots_loadout_rank" ) == "" ) // what rank the bots should be around, -1 is around the players, 0 is all random
		setDvar( "bots_loadout_rank", -1 );

	if ( getDvar( "bots_loadout_codpoints" ) == "" ) // how much cod points a bot should have, -1 is around the players, 0 is all random
		setDvar( "bots_loadout_codpoints", -1 );

	if ( getDvar( "bots_loadout_prestige" ) == "" ) // what pretige the bots will be, -1 is the players, -2 is random
		setDvar( "bots_loadout_prestige", -1 );

	if ( getDvar( "bots_play_target_other" ) == "" ) //bot target non play ents (vehicles)
		setDvar( "bots_play_target_other", true );

	if ( getDvar( "bots_play_killstreak" ) == "" ) //bot use killstreaks
		setDvar( "bots_play_killstreak", true );

	if ( getDvar( "bots_play_nade" ) == "" ) //bots grenade
		setDvar( "bots_play_nade", true );

	if ( getDvar( "bots_play_knife" ) == "" ) //bots knife
		setDvar( "bots_play_knife", true );

	if ( getDvar( "bots_play_fire" ) == "" ) //bots fire
		setDvar( "bots_play_fire", true );

	if ( getDvar( "bots_play_move" ) == "" ) //bots move
		setDvar( "bots_play_move", true );

	if ( getDvar( "bots_play_take_carepackages" ) == "" ) //bots take carepackages
		setDvar( "bots_play_take_carepackages", true );

	if ( getDvar( "bots_play_obj" ) == "" ) //bots play the obj
		setDvar( "bots_play_obj", true );

	if ( getDvar( "bots_play_camp" ) == "" ) //bots camp and follow
		setDvar( "bots_play_camp", true );

	if ( getDvar( "bots_play_aim" ) == "" )
		setDvar( "bots_play_aim", true );

	if ( getDvar( "bots_play_jumpdrop" ) == "" ) //bots jump and dropshot
		setDvar( "bots_play_jumpdrop", true );

	level.bots = [];
	level.bot_decoys = [];
	level.bot_planes = [];

	if ( !isDefined( game["botWarfare"] ) )
		game["botWarfare"] = true;

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
		wait 0.05;

	setDvar( "bots_manage_add", getBotArray().size );

	if ( !getDvarInt( "bots_main_kickBotsAtEnd" ) )
		return;

	bots = getBotArray();

	for ( i = 0; i < bots.size; i++ )
	{
		kick( bots[i] getEntityNumber() );
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
		return;

	self thread maps\mp\bots\_bot_script::connected();

	level.bots[level.bots.size] = self;
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

		if ( GetDvarInt( "bots_main_debug" ) >= 2 )
		{
			big_str = "Bot Warfare debug: " + self.name + ": " + msg + ": " + str;

			if ( isDefined( b ) && isString( b ) )
				big_str += ": " + b;

			if ( isDefined( c ) && isString( c ) )
				big_str += ": " + c;

			if ( isDefined( d ) && isString( d ) )
				big_str += ": " + d;

			if ( isDefined( e ) && isString( e ) )
				big_str += ": " + e;

			if ( isDefined( f ) && isString( f ) )
				big_str += ": " + f;

			if ( isDefined( g ) && isString( g ) )
				big_str += ": " + g;

			BotBuiltinPrintConsole( big_str );
		}
		else if ( msg == "debug" && GetDvarInt( "bots_main_debug" ) )
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

		if ( getDvar( "bots_skill" ) != "" )
		{
			SetDvar( "bot_difficulty", getDvar( "bots_skill" ) );
			setDvar( "bots_skill", "" );
		}

		bot_set_difficulty( GetDvar( #"bot_difficulty" ) );
	}
}

/*
	Setup bot dvars for non dedicated clients
*/
doNonDediBots()
{
	if ( !GetDvarInt( #"xblive_basictraining" ) )
		return;

	if ( isDefined( game[ "bots_spawned" ] ) )
		return;

	game[ "bots_spawned" ] = true;

	if ( getDvar( "bot_enemies_extra" ) == "" )
		setDvar( "bot_enemies_extra", 0 );

	if ( getDvar( "bot_friends_extra" ) == "" )
		setDvar( "bot_friends_extra", 0 );

	bot_friends = GetDvarInt( #"bot_friends" );
	bot_enemies = GetDvarInt( #"bot_enemies" );

	bot_enemies += GetDvarInt( "bot_enemies_extra" );
	bot_friends += GetDvarInt( "bot_friends_extra" );

	bot_wait_for_host();
	host = GetHostPlayer();

	team = "allies";

	if ( isDefined( host ) && isDefined( host.pers[ "team" ] ) && ( host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis" ) )
		team = host.pers[ "team" ];

	setDvar( "bots_manage_add", bot_enemies + bot_friends - 1 );
	setDvar( "bots_manage_fill", bot_enemies + bot_friends );
	setDvar( "bots_manage_fill_mode", 0 );
	setDvar( "bots_manage_fill_kick", true );
	setDvar( "bots_manage_fill_spec", false );

	setDvar( "bots_team", "custom" );

	if ( team == "axis" )
		setDvar( "bots_team_amount", bot_friends );
	else
		setDvar( "bots_team_amount", bot_enemies );

	setDvar( "bots_team_force", true );
	setDvar( "bots_team_mode", 0 );
}

/*
	Sets the difficulty of the bots
*/
bot_set_difficulty( difficulty )
{
	if ( difficulty == "fu" )
	{
		SetDvar( "sv_botMinDeathTime",		"250" );
		SetDvar( "sv_botMaxDeathTime",		"500" );
		SetDvar( "sv_botMinFireTime",		"100" );
		SetDvar( "sv_botMaxFireTime",		"300" );
		SetDvar( "sv_botYawSpeed",			"14" );
		SetDvar( "sv_botYawSpeedAds",		"14" );
		SetDvar( "sv_botPitchUp",			"-5" );
		SetDvar( "sv_botPitchDown",			"10" );
		SetDvar( "sv_botFov",				"160" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"100" );
		SetDvar( "sv_botMaxCrouchTime",		"400" );
		SetDvar( "sv_botTargetLeadBias",	"2" );
		SetDvar( "sv_botMinReactionTime",	"30" );
		SetDvar( "sv_botMaxReactionTime",	"100" );
		SetDvar( "sv_botStrafeChance",		"1" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"512" );
		SetDvar( "sv_botAllowGrenades",		"1"	);
		SetDvar( "sv_botMinGrenadeTime",	"1500" );
		SetDvar( "sv_botMaxGrenadeTime",	"4000" );
		SetDvar( "sv_botSprintDistance",	"512"	);
		SetDvar( "sv_botMeleeDist",			"80" );
	}
	else if ( difficulty == "hard" )
	{
		SetDvar( "sv_botMinDeathTime",		"250" );
		SetDvar( "sv_botMaxDeathTime",		"500" );
		SetDvar( "sv_botMinFireTime",		"400" );
		SetDvar( "sv_botMaxFireTime",		"600" );
		SetDvar( "sv_botYawSpeed",			"8" );
		SetDvar( "sv_botYawSpeedAds",		"10" );
		SetDvar( "sv_botPitchUp",			"-5" );
		SetDvar( "sv_botPitchDown",			"10" );
		SetDvar( "sv_botFov",				"100" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"100" );
		SetDvar( "sv_botMaxCrouchTime",		"400" );
		SetDvar( "sv_botTargetLeadBias",	"2" );
		SetDvar( "sv_botMinReactionTime",	"400" );
		SetDvar( "sv_botMaxReactionTime",	"700" );
		SetDvar( "sv_botStrafeChance",		"0.9" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"384" );
		SetDvar( "sv_botAllowGrenades",		"1"	);
		SetDvar( "sv_botMinGrenadeTime",	"1500" );
		SetDvar( "sv_botMaxGrenadeTime",	"4000" );
		SetDvar( "sv_botSprintDistance",	"512"	);
		SetDvar( "sv_botMeleeDist",			"80" );
	}
	else if ( difficulty == "easy" )
	{
		SetDvar( "sv_botMinDeathTime",		"1000" );
		SetDvar( "sv_botMaxDeathTime",		"2000" );
		SetDvar( "sv_botMinFireTime",		"900" );
		SetDvar( "sv_botMaxFireTime",		"1000" );
		SetDvar( "sv_botYawSpeed",			"2" );
		SetDvar( "sv_botYawSpeedAds",		"2.5" );
		SetDvar( "sv_botPitchUp",			"-20" );
		SetDvar( "sv_botPitchDown",			"40" );
		SetDvar( "sv_botFov",				"50" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"4000" );
		SetDvar( "sv_botMaxCrouchTime",		"6000" );
		SetDvar( "sv_botTargetLeadBias",	"8" );
		SetDvar( "sv_botMinReactionTime",	"1200" );
		SetDvar( "sv_botMaxReactionTime",	"1600" );
		SetDvar( "sv_botStrafeChance",		"0.1" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"256" );
		SetDvar( "sv_botAllowGrenades",		"0"	);
		SetDvar( "sv_botSprintDistance",	"1024"	);
		SetDvar( "sv_botMeleeDist",			"40" );
	}
	else // 'normal' difficulty
	{
		if ( difficulty != "normal" )
			return;

		SetDvar( "sv_botMinDeathTime",		"500" );
		SetDvar( "sv_botMaxDeathTime",		"1000" );
		SetDvar( "sv_botMinFireTime",		"600" );
		SetDvar( "sv_botMaxFireTime",		"800" );
		SetDvar( "sv_botYawSpeed",			"4" );
		SetDvar( "sv_botYawSpeedAds",		"5" );
		SetDvar( "sv_botPitchUp",			"-10" );
		SetDvar( "sv_botPitchDown",			"20" );
		SetDvar( "sv_botFov",				"70" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"2000" );
		SetDvar( "sv_botMaxCrouchTime",		"4000" );
		SetDvar( "sv_botTargetLeadBias",	"4" );
		SetDvar( "sv_botMinReactionTime",	"800" );
		SetDvar( "sv_botMaxReactionTime",	"1200" );
		SetDvar( "sv_botStrafeChance",		"0.6" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"256" );
		SetDvar( "sv_botAllowGrenades",		"1"	);
		SetDvar( "sv_botMinGrenadeTime",	"1500" );
		SetDvar( "sv_botMaxGrenadeTime",	"4000" );
		SetDvar( "sv_botSprintDistance",	"512"	);
		SetDvar( "sv_botMeleeDist",			"80" );
		difficulty = "normal";
	}

	if ( level.gameType == "oic" && difficulty == "fu" )
	{
		SetDvar( "sv_botMinReactionTime",		"400" );
		SetDvar( "sv_botMaxReactionTime",		"500" );
		SetDvar( "sv_botMinAdsTime",		"1000" );
		SetDvar( "sv_botMaxAdsTime",		"2000" );
	}

	if ( level.gameType == "oic" && ( difficulty == "hard" || difficulty == "fu" ) )
	{
		SetDvar( "sv_botSprintDistance",	"256" );
	}

	if ( !getDvarInt( "bots_play_nade" ) )
		SetDvar( "sv_botAllowGrenades",		"0"	);

	if ( !getDvarInt( "bots_play_aim" ) )
	{
		setdvar( "sv_botYawSpeed", "0" );
		setdvar( "sv_botYawSpeedAds", "0" );
		setdvar( "sv_botPitchUp", "0" );
		setdvar( "sv_botPitchDown", "0" );
	}

	SetDvar( "bot_difficulty", difficulty );
	SetDvar( "scr_bot_difficulty", difficulty );
	SetDvar( "splitscreen_botDifficulty", difficulty );
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots_loop()
{
	teamAmount = getDvarInt( "bots_team_amount" );
	toTeam = getDvar( "bots_team" );

	alliesbots = 0;
	alliesplayers = 0;
	axisbots = 0;
	axisplayers = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( !isDefined( player.pers["team"] ) )
			continue;

		if ( player is_bot() )
		{
			if ( player.pers["team"] == "allies" )
				alliesbots++;
			else if ( player.pers["team"] == "axis" )
				axisbots++;
		}
		else
		{
			if ( player.pers["team"] == "allies" )
				alliesplayers++;
			else if ( player.pers["team"] == "axis" )
				axisplayers++;
		}
	}

	allies = alliesbots;
	axis = axisbots;

	if ( !getDvarInt( "bots_team_mode" ) )
	{
		allies += alliesplayers;
		axis += axisplayers;
	}

	if ( toTeam != "custom" )
	{
		if ( getDvarInt( "bots_team_force" ) )
		{
			if ( toTeam == "autoassign" )
			{
				if ( abs( axis - allies ) > 1 )
				{
					toTeam = "axis";

					if ( axis > allies )
						toTeam = "allies";
				}
			}

			if ( toTeam != "autoassign" )
			{
				playercount = level.players.size;

				for ( i = 0; i < playercount; i++ )
				{
					player = level.players[i];

					if ( !isDefined( player.pers["team"] ) )
						continue;

					if ( !player is_bot() )
						continue;

					if ( player.pers["team"] == toTeam )
						continue;

					if ( toTeam == "allies" )
						player thread [[level.allies]]();
					else if ( toTeam == "axis" )
						player thread [[level.axis]]();
					else
						player thread [[level.spectator]]();

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
			player = level.players[i];

			if ( !isDefined( player.pers["team"] ) )
				continue;

			if ( !player is_bot() )
				continue;

			if ( player.pers["team"] == "axis" )
			{
				if ( axis > teamAmount )
				{
					player thread [[level.allies]]();
					break;
				}
			}
			else
			{
				if ( axis < teamAmount )
				{
					player thread [[level.axis]]();
					break;
				}
				else if ( player.pers["team"] != "allies" )
				{
					player thread [[level.allies]]();
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
	botsToAdd = GetDvarInt( "bots_manage_add" );

	if ( botsToAdd > 0 )
	{
		SetDvar( "bots_manage_add", 0 );

		if ( botsToAdd > 64 )
			botsToAdd = 64;

		for ( ; botsToAdd > 0; botsToAdd-- )
		{
			level add_bot();
			wait 0.25;
		}
	}

	fillMode = getDVarInt( "bots_manage_fill_mode" );

	if ( fillMode == 2 || fillMode == 3 )
		setDvar( "bots_manage_fill", getGoodMapAmount() );

	fillAmount = getDvarInt( "bots_manage_fill" );

	players = 0;
	bots = 0;
	spec = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( player isdemoclient() )
			continue;

		if ( player is_bot() )
			bots++;
		else if ( !isDefined( player.pers["team"] ) || ( player.pers["team"] != "axis" && player.pers["team"] != "allies" ) )
			spec++;
		else
			players++;
	}

	if ( fillMode == 4 )
	{
		axisplayers = 0;
		alliesplayers = 0;

		playercount = level.players.size;

		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[i];

			if ( player is_bot() )
				continue;

			if ( !isDefined( player.pers["team"] ) )
				continue;

			if ( player.pers["team"] == "axis" )
				axisplayers++;
			else if ( player.pers["team"] == "allies" )
				alliesplayers++;
		}

		result = fillAmount - abs( axisplayers - alliesplayers ) + bots;

		if ( players == 0 )
		{
			if ( bots < fillAmount )
				result = fillAmount - 1;
			else if ( bots > fillAmount )
				result = fillAmount + 1;
			else
				result = fillAmount;
		}

		bots = result;
	}

	if ( !randomInt( 999 ) )
	{
		setDvar( "testclients_doreload", true );
		wait 0.1;
		setDvar( "testclients_doreload", false );
		doExtraCheck();
	}

	amount = bots;

	if ( fillMode == 0 || fillMode == 2 )
		amount += players;

	if ( getDVarInt( "bots_manage_fill_spec" ) )
		amount += spec;

	if ( amount < fillAmount )
		setDvar( "bots_manage_add", 1 );
	else if ( amount > fillAmount && getDvarInt( "bots_manage_fill_kick" ) )
	{
		tempBot = getBotToKick();

		if ( isDefined( tempBot ) )
			kick( tempBot getEntityNumber(), "EXE_PLAYERKICKED" );
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
		bot.pers["isBot"] = true;
		bot.pers["isBotWarfare"] = true;
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
	if ( !IsDefined( self ) )
	{
		return false;
	}

	if ( !IsAlive( self ) )
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

	if ( self HasScriptGoal() )
	{
		return false;
	}

	if ( IsDefined( self GetThreat() ) )
	{
		return false;
	}

	if ( self IsRemoteControlling() || self.bot_lock_goal )
	{
		return false;
	}

	if ( self UseButtonPressed() )
		return false;

	if ( self isPlanting() )
		return false;

	if ( self isDefusing() )
		return false;

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

		if ( !isDefined( g ) )
			continue;

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

	level.bot_decoys[level.bot_decoys.size] = g;

	g waittill( "death" );

	for ( entry = 0; entry < level.bot_decoys.size; entry++ )
	{
		if ( level.bot_decoys[entry] == g )
		{
			while ( entry < level.bot_decoys.size - 1 )
			{
				level.bot_decoys[entry] = level.bot_decoys[entry + 1];
				entry++;
			}

			level.bot_decoys[entry] = undefined;
			break;
		}
	}
}

/*
	Attach a trigger to the scrambler
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

	while ( !isDefined( self.owner ) || !isDefined( self.owner.team ) )
		wait 0.05;

	self.team = self.owner.team;

	for ( ;; )
	{
		trig waittill( "trigger", player );

		if ( !isDefined( player ) || !isDefined( player.team ) )
			continue;

		if ( self maps\mp\gametypes\_weaponobjects::isStunned() )
			continue;

		if ( isDefined( self.owner ) && player == self.owner )
			continue;

		if ( level.teamBased && self.team == player.team )
			continue;

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

	if ( isDefined( self ) )
		self.bot_scrambled = false;
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
	ents = GetEntArray( "script_model", "classname" );

	for ( i = 0; i < ents.size; i++ )
	{
		ent = ents[i];

		if ( isDefined( ent.bot_plane ) )
			continue;

		if ( ent.model != level.spyplanemodel )
			continue;

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

	level.bot_planes[level.bot_planes.size] = ent;

	ent waittill_any( "death", "delete", "leaving" );

	for ( entry = 0; entry < level.bot_planes.size; entry++ )
	{
		if ( level.bot_planes[entry] == ent )
		{
			while ( entry < level.bot_planes.size - 1 )
			{
				level.bot_planes[entry] = level.bot_planes[entry + 1];
				entry++;
			}

			level.bot_planes[entry] = undefined;
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
		if ( isDefined( level.bombZones ) && level.gametype == "sd" )
		{
			level.isKillBoosting = ::bot_killBoost;

			for ( i = 0; i < level.bombZones.size; i++ )
				level.bombZones[i].onUse = ::bot_onUsePlantObjectFix;

			break;
		}

		wait 0.05;
	}
}
