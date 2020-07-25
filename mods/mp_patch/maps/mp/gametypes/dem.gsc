#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
// Rallypoints should be destroyed on leaving your team/getting killed
// Compass icons need to be looked at
// Doesn't seem to be setting angle on spawn so that you are facing your rallypoint

/*
	Demolition
	Attackers objective: Bomb 2 positions
	Defenders objective: Defend these 2 positions / Defuse planted bombs
	Round ends:	When both bomb positions are exploded, or roundlength time is reached
	Map ends:	When one team reaches the score limit, or time limit or round limit is reached
	Respawning:	Players respawn upon death

	Level requirements
	------------------
		Allied Spawnpoints:
			classname		mp_dem_spawn_attacker_start
			Allied players spawn from these. Place at least 16 of these relatively close together.

		Axis Spawnpoints:
			classname		mp_dem_spawn_defender_start
			Axis players spawn from these. Place at least 16 of these relatively close together.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

		Bombzones:
			classname					trigger_multiple
			targetname					bombzone_dem
			script_gameobjectname		bombzone_dem
			script_bombmode_original	<if defined this bombzone will be used in the original bomb mode>
			script_bombmode_single		<if defined this bombzone will be used in the single bomb mode>
			script_bombmode_dual		<if defined this bombzone will be used in the dual bomb mode>
			script_team					Set to allies or axis. This is used to set which team a bombzone is used by in dual bomb mode.
			script_label				Set to A or B. This sets the letter shown on the compass in original mode.
			This is a volume of space in which the bomb can planted. Must contain an origin brush.

		Bomb:
			classname				trigger_lookat
			targetname				bombtrigger
			script_gameobjectname	bombzone
			This should be a 16x16 unit trigger with an origin brush placed so that it's center lies on the bottom plane of the trigger.
			Must be in the level somewhere. This is the trigger that is used when defusing a bomb.
			It gets moved to the position of the planted bomb model.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "marines";
			game["axis"] = "nva";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.

			game["attackers"] = "allies";
			game["defenders"] = "axis";
			This sets which team is attacking and which team is defending. Attackers plant the bombs. Defenders protect the targets.

		If using minefields or exploders:
			maps\mp\_load::main();

	Optional level script settings
	------------------------------
		Soldier Type and Variation:
			game["american_soldiertype"] = "normandy";
			game["german_soldiertype"] = "normandy";
			This sets what character models are used for each nationality on a particular map.

			Valid settings:
				american_soldiertype	normandy
				british_soldiertype		normandy, africa
				russian_soldiertype		coats, padded
				german_soldiertype		normandy, africa, winterlight, winterdark

		Exploder Effects:
			Setting script_noteworthy on a bombzone trigger to an exploder group can be used to trigger additional effects.
*/

/*QUAKED mp_dem_spawn_attacker_start (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Attacking players spawn randomly at one of these positions at the beginning of a round.*/

/*QUAKED mp_dem_spawn_defender_start (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Defending players spawn randomly at one of these positions at the beginning of a round.*/

/*QUAKED mp_dem_spawn_attacker (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Attacking players may spawn randomly at one of these positions after death.*/

/*QUAKED mp_dem_spawn_attacker_a (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Attacking players may spawn randomly at one of these positions after death if site A has been destroyed.*/

/*QUAKED mp_dem_spawn_attacker_b (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Attacking players may spawn randomly at one of these positions after death if site B has been destroyed.*/

/*QUAKED mp_dem_spawn_defender (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Defending players may spawn randomly at one of these positions after death.*/

/*QUAKED mp_dem_spawn_defender_a (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Defending players may spawn randomly at one of these positions after death if site A is still intact.*/

/*QUAKED mp_dem_spawn_defender_b (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Defending players may spawn randomly at one of these positions after death if site B is still intact.*/

main()
{
	if(GetDvar( #"mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic_utils::registerRoundSwitchDvar( level.gameType, 1, 0, 9 );
	maps\mp\gametypes\_globallogic_utils::registerTimeLimitDvar( level.gameType, 2.5, 0, 1440 );
	maps\mp\gametypes\_globallogic_utils::registerScoreLimitDvar( level.gameType, 2, 0, 500 );
	maps\mp\gametypes\_globallogic_utils::registerRoundLimitDvar( level.gameType, 0, 0, 12 );
	maps\mp\gametypes\_globallogic_utils::registerRoundWinLimitDvar( level.gameType, 0, 0, 10 );
	maps\mp\gametypes\_globallogic_utils::registerNumLivesDvar( level.gameType, 0, 0, 10 );

	maps\mp\gametypes\_weapons::registerGrenadeLauncherDudDvar( level.gameType, 10, 0, 1440 );
	maps\mp\gametypes\_weapons::registerThrownGrenadeDudDvar( level.gameType, 0, 0, 1440 );
	maps\mp\gametypes\_weapons::registerKillstreakDelay( level.gameType, 0, 0, 1440 );
	
	maps\mp\gametypes\_globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );
	
	registerGrenadeLauncherDudDvar( level.gameType, 2, 0, 1440 );
	registerThrownGrenadeDudDvar( level.gameType, 0, 0, 1440 );

	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onSpawnPlayerUnified = ::onSpawnPlayerUnified;
	level.playerSpawnedCB = ::dem_playerSpawnedCB;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	level.getTeamKillPenalty = ::dem_getTeamKillPenalty;
	level.getTeamKillScore = ::dem_getTeamKillScore;
	level.gamemodeSpawnDvars = ::gamemodeSpawnDvars;
	level.getTimeLimitDvarValue = ::getTimeLimitDvarValue;
	level.ddBombModel = [];
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "demo_start";
	game["dialog"]["gametype_hardcore"] = "hcdemo_start";
	game["dialog"]["offense_obj"] = "destroy_start";
	game["dialog"]["defense_obj"] = "defend_start";
	game["dialog"]["sudden_death"] = "suddendeath";
	
	// Sets the scoreboard columns and determines with data is sent across the network
	setscoreboardcolumns( "kills", "deaths", "plants", "defuses" ); 
}

onPrecacheGameType()
{
	game["bombmodelname"] = "t5_weapon_briefcase_bomb_world";
	game["bombmodelnameobj"] = "t5_weapon_briefcase_bomb_world";
	game["bomb_dropped_sound"] = "flag_drop_plr";
	game["bomb_recovered_sound"] = "flag_pickup_plr";
	precacheModel(game["bombmodelname"]);
	precacheModel(game["bombmodelnameobj"]);

	precacheShader("waypoint_bomb");
	precacheShader("hud_suitcase_bomb");
	precacheShader("waypoint_target");
	precacheShader("waypoint_target_a");
	precacheShader("waypoint_target_b");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defend_a");
	precacheShader("waypoint_defend_b");
	precacheShader("waypoint_defuse");
	precacheShader("waypoint_defuse_a");
	precacheShader("waypoint_defuse_b");
	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_target_a");
	precacheShader("compass_waypoint_target_b");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defend_a");
	precacheShader("compass_waypoint_defend_b");
	precacheShader("compass_waypoint_defuse");
	precacheShader("compass_waypoint_defuse_a");
	precacheShader("compass_waypoint_defuse_b");
	
	precacheString( &"MP_EXPLOSIVES_RECOVERED_BY" );
	precacheString( &"MP_EXPLOSIVES_DROPPED_BY" );
	precacheString( &"MP_EXPLOSIVES_PLANTED_BY" );
	precacheString( &"MP_EXPLOSIVES_DEFUSED_BY" );
	precacheString( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	precacheString( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	precacheString( &"MP_PLANTING_EXPLOSIVE" );	
	precacheString( &"MP_DEFUSING_EXPLOSIVE" );	
	precacheString( &"MP_TIME_EXTENDED" );
}

dem_getTeamKillPenalty( eInflictor, attacker, sMeansOfDeath, sWeapon )
{
	teamkill_penalty = maps\mp\gametypes\_globallogic_defaults::default_getTeamKillPenalty( eInflictor, attacker, sMeansOfDeath, sWeapon );

	if ( ( isdefined( self.isDefusing ) && self.isDefusing ) || ( isdefined( self.isPlanting ) && self.isPlanting ) )
	{
		teamkill_penalty = teamkill_penalty * level.teamKillPenaltyMultiplier;
	}
	
	return teamkill_penalty;
}

dem_getTeamKillScore( eInflictor, attacker, sMeansOfDeath, sWeapon )
{
	teamkill_score = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" );
	
	if ( ( isdefined( self.isDefusing ) && self.isDefusing ) || ( isdefined( self.isPlanting ) && self.isPlanting ) )
	{
		teamkill_score = teamkill_score * level.teamKillScoreMultiplier;
	}
	
	return int(teamkill_score);
}


onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedsides"] = !game["switchedsides"];
		}
		else
		{
			level.halftimeSubCaption = "";
		}
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}

getBetterTeam()
{
	kills["allies"] = 0;
	kills["axis"] = 0;
	deaths["allies"] = 0;
	deaths["axis"] = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		team = player.pers["team"];
		if ( isDefined( team ) && (team == "allies" || team == "axis") )
		{
			kills[ team ] += player.kills;
			deaths[ team ] += player.deaths;
		}
	}
	
	if ( kills["allies"] > kills["axis"] )
		return "allies";
	else if ( kills["axis"] > kills["allies"] )
		return "axis";
	
	// same number of kills

	if ( deaths["allies"] < deaths["axis"] )
		return "allies";
	else if ( deaths["axis"] < deaths["allies"] )
		return "axis";
	
	// same number of deaths
	
	if ( randomint(2) == 0 )
		return "allies";
	return "axis";
}

gamemodeSpawnDvars(reset_dvars)
{
	ss = level.spawnsystem;
		
	// negative influencer around enemy base
	ss.dem_enemy_base_influencer_score =	set_dvar_float_if_unset("scr_spawn_dem_enemy_base_influencer_score", "-500", reset_dvars);
	ss.dem_enemy_base_influencer_score_curve =	set_dvar_if_unset("scr_spawn_dem_enemy_base_influencer_score_curve", "constant", reset_dvars);
	ss.dem_enemy_base_influencer_radius =	set_dvar_float_if_unset("scr_spawn_dem_enemy_base_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
}

onStartGameType()
{
	SetBombTimer( "A", 0 );
	setMatchFlag( "bomb_timer_a", 0 );
	SetBombTimer( "B", 0 );
	setMatchFlag( "bomb_timer_b", 0 );
	
	level.usingExtraTime = false;
	
	// we'll handle the sideswitching ourselves
	level.spawnsystem.unifiedSideSwitching = 0;
	
	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}
	
	setClientNameMode( "manual_change" );
	
	game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
	game["strings"]["bomb_defused"] = &"MP_BOMB_DEFUSED";
	
	precacheString( game["strings"]["target_destroyed"] );
	precacheString( game["strings"]["bomb_defused"] );

	level._effect["bombexplosion"] = loadfx("maps/mp_maps/fx_mp_exp_bomb");
	
	maps\mp\gametypes\_globallogic_ui::setObjectiveText( game["attackers"], &"OBJECTIVES_DEM_ATTACKER" );
	maps\mp\gametypes\_globallogic_ui::setObjectiveText( game["defenders"], &"OBJECTIVES_SD_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( game["attackers"], &"OBJECTIVES_DEM_ATTACKER" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( game["defenders"], &"OBJECTIVES_SD_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( game["attackers"], &"OBJECTIVES_DEM_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( game["defenders"], &"OBJECTIVES_SD_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( game["attackers"], &"OBJECTIVES_DEM_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( game["defenders"], &"OBJECTIVES_SD_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::dropSpawnPoints( "mp_dem_spawn_attacker_a" );
	maps\mp\gametypes\_spawnlogic::dropSpawnPoints( "mp_dem_spawn_attacker_b" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dem_spawn_defender_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dem_spawn_attacker_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["attackers"], "mp_dem_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["defenders"], "mp_dem_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["defenders"], "mp_dem_spawn_defender_a" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["defenders"], "mp_dem_spawn_defender_b" );
	maps\mp\gametypes\_spawning::updateAllSpawnPoints();
	
		level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	spawnpoint = maps\mp\gametypes\_spawnlogic::getRandomIntermissionPoint();
	setDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );
	
	level.demBombzoneName = "bombzone_dem";
	bombZones = getEntArray( level.demBombzoneName, "targetname" );
	if ( bombZones.size == 0 )
		level.demBombzoneName = "bombzone";
	
	allowed[0] = "sd";
	allowed[1] = level.demBombzoneName;
	allowed[2] = "blocker";
	allowed[3] = "dem";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// now that the game objects have been deleted place the influencers
	maps\mp\gametypes\_spawning::create_map_placed_influencers();

	level.spawn_axis_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dem_spawn_defender_start" );
	level.spawn_allies_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dem_spawn_attacker_start" );
	
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "plant", 100 );
	maps\mp\gametypes\_rank::registerScoreInfo( "defuse", 100 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_75", 25 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_50", 25 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_25", 25 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 25 );
	maps\mp\gametypes\_rank::registerScoreInfo( "destroyer", 100 );
		
	thread updateGametypeDvars();
	
	thread bombs();
}


onSpawnPlayerUnified()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	if ( isDefined( self.carryIcon ) )
	{
		self.carryIcon destroyElem();
		self.carryIcon = undefined;
	}
	
	if ( self.pers["team"] == game["attackers"] )
	{
		if ( self IsSplitscreen() )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon.x = -125;
			self.carryIcon.y = -90;
			self.carryIcon.horzAlign = "right";
			self.carryIcon.vertAlign = "bottom";
		}
		else
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 50, 50 );
			self.carryIcon.x = -130;
			self.carryIcon.y = -103;
			self.carryIcon.horzAlign = "user_right";
			self.carryIcon.vertAlign = "user_bottom";
		}
		self.carryIcon.alpha = 0.75;
		self.carryIcon.hidewhileremotecontrolling = true;
		self.carryIcon.hidewheninkillcam = true;
	}
	
	maps\mp\gametypes\_spawning::onSpawnPlayer_Unified();
}


onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	if ( isDefined( self.carryIcon ) )
	{
		self.carryIcon destroyElem();
		self.carryIcon = undefined;
	}

	if( self.pers["team"] == game["attackers"] )
		spawnPointName = "mp_dem_spawn_attacker_start";
	else
		spawnPointName = "mp_dem_spawn_defender_start";

	if ( self.pers["team"] == game["attackers"] )
	{
		if ( self IsSplitscreen() )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon.x = -125;
			self.carryIcon.y = -90;
			self.carryIcon.horzAlign = "right";
			self.carryIcon.vertAlign = "bottom";
		}
		else
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 50, 50 );
			self.carryIcon.x = -130;
			self.carryIcon.y = -103;
			self.carryIcon.horzAlign = "user_right";
			self.carryIcon.vertAlign = "user_bottom";
		}
		self.carryIcon.alpha = 0.75;
		self.carryIcon.hidewhileremotecontrolling = true;
		self.carryIcon.hidewheninkillcam = true;
	}

	spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( spawnPointName );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

	self spawn( spawnpoint.origin, spawnpoint.angles, "dem" );
}


dem_playerSpawnedCB()
{
	level notify ( "spawned_player" );
}


onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	thread checkAllowSpectating();
	
	inBombZone = false;
	
	for ( index = 0; index < level.bombZones.size; index++ )
	{
		if ( !isDefined( level.bombZones[index].bombExploded ) || !level.bombZones[index].bombExploded )
		{
			dist = Distance2d(self.origin, level.bombZones[index].curorigin);
			if ( dist < level.defaultOffenseRadius )
			{
				inBombZone = true;
				break;
			}
		}
	}
	

	if ( inBombZone && isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] && ( !isdefined( sWeapon ) || !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) ) )
	{	
		if ( game["defenders"] == self.pers["team"] )
		{
			attacker maps\mp\_medals::offense( sWeapon );
			attacker maps\mp\gametypes\_persistence::statAddWithGameType( "OFFENDS", 1 );
		}
		else
		{			
			if( isdefined(attacker.pers["defends"]) )
			{
				attacker.pers["defends"]++;
				attacker.defends = attacker.pers["defends"];
			}

			attacker maps\mp\_medals::defense( sWeapon );
			attacker maps\mp\gametypes\_persistence::statAddWithGameType( "DEFENDS", 1 );
		}
	}
}


checkAllowSpectating()
{
	wait ( 0.05 );
	
	update = false;

	livesLeft = !(level.numLives && !self.pers["lives"]);

	if ( !level.aliveCount[ game["attackers"] ] && !livesLeft )
	{
		level.spectateOverride[game["attackers"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( !level.aliveCount[ game["defenders"] ] && !livesLeft )
	{
		level.spectateOverride[game["defenders"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( update )
		maps\mp\gametypes\_spectating::updateSpectateSettings();
}


dem_endGame( winningTeam, endReasonText )
{
	if ( isdefined( winningTeam ) )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

dem_endGameWithKillcam( winningTeam, endReasonText )
{
	level thread maps\mp\gametypes\_killcam::startLastKillcam();
	dem_endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	if ( level.bombExploded || level.bombDefused )
		return;
	
	if ( team == "all" )
	{
		if ( level.bombPlanted )
			dem_endGameWithKillcam( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
		else
			dem_endGameWithKillcam( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		if ( level.bombPlanted )
			return;
		
		dem_endGameWithKillcam( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		dem_endGameWithKillcam( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}


onOneLeftEvent( team )
{
	if ( level.bombExploded || level.bombDefused )
		return;
	
	//if ( team == game["attackers"] )
	warnLastPlayer( team );
}


onTimeLimit()
{
	if ( level.teamBased )
	{
		bombZonesLeft = 0;
		
		for ( index = 0; index < level.bombZones.size; index++ )
		{
			if ( !isDefined( level.bombZones[index].bombExploded ) || !level.bombZones[index].bombExploded )
				bombZonesLeft++;
		}
		if ( bombZonesLeft == 0 )
		{
			dem_endGame( game["attackers"], game["strings"]["target_destroyed"] );
		}
		else 
		{
			dem_endGame( game["defenders"], game["strings"]["time_limit_reached"] );
		}
	}
	else
		dem_endGame( undefined, game["strings"]["time_limit_reached"] );
}


warnLastPlayer( team )
{
	if ( !isdefined( level.warnedLastPlayer ) )
		level.warnedLastPlayer = [];
	
	if ( isDefined( level.warnedLastPlayer[team] ) )
		return;
		
	level.warnedLastPlayer[team] = true;

	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( isDefined( player.pers["team"] ) && player.pers["team"] == team && isdefined( player.pers["class"] ) )
		{
			if ( player.sessionstate == "playing" && !player.afk )
				break;
		}
	}
	
	if ( i == players.size )
		return;
	
	players[i] thread giveLastAttackerWarning();
}


giveLastAttackerWarning()
{
	self endon("death");
	self endon("disconnect");
	
	fullHealthTime = 0;
	interval = .05;
	
	while(1)
	{
		if ( self.health != self.maxhealth )
			fullHealthTime = 0;
		else
			fullHealthTime += interval;
		
		wait interval;
		
		if (self.health == self.maxhealth && fullHealthTime >= 3)
			break;
	}
	
	//self iprintlnbold(&"MP_YOU_ARE_THE_ONLY_REMAINING_PLAYER");
	//self maps\mp\gametypes\_globallogic_audio::leaderDialogOnPlayer( "last_alive" );
	self maps\mp\gametypes\_globallogic_audio::leaderDialogOnPlayer( "sudden_death" );
	
	self maps\mp\gametypes\_missions::lastManSD();
}


updateGametypeDvars()
{
	level.plantTime = dvarFloatValue( "planttime", 5, 0, 20 );
	level.defuseTime = dvarFloatValue( "defusetime", 5, 0, 20 );
	level.bombTimer = dvarFloatValue( "bombtimer", 45, 1, 300 );
	level.extraTime = dvarFloatValue( "extratime", 2.5, 0, 300 );

	level.teamKillPenaltyMultiplier = dvarFloatValue( "teamkillpenalty", 2, 0, 10 );
	level.teamKillScoreMultiplier = dvarFloatValue( "teamkillscore", 4, 0, 40 );
	level.playerEventsMax = dvarFloatValue( "maxPlayerEvents", 1000, 0, 1000 );
	level.playerEventsLPM = dvarFloatValue( "maxPlayerEventsPerMinute", 2, 0, 15 );
	level.bombEventsLPM = dvarFloatValue( "maxBombEventsPerMinute", 4, 0, 15 );
}

resetBombZone()
{
	self maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( level.ddBomb );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_target" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + self.label );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self.useWeapon = "briefcase_bomb_mp";
}

setUpForDefusing()
{
	self maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( undefined );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + self.label );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
}


bombs()
{
	level.bombAPlanted = false;
	level.bombBPlanted = false;
	level.bombPlanted = false;
	level.bombDefused = false;
	level.bombExploded = false;
	
	sdBomb = getEnt( "sd_bomb", "targetname" );
	if ( isDefined( sdBomb ) )
		sdBomb delete();

	precacheModel( "t5_weapon_briefcase_bomb_world" );	
	
	level.bombZones = [];
	
	bombZones = getEntArray( level.demBombzoneName, "targetname" );
	
	for ( index = 0; index < bombZones.size; index++ )
	{
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
		bombZone maps\mp\gametypes\_gameobjects::setKeyObject( level.ddBomb );

		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		bombZone.label = label;
		bombZone.index = index;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		bombZone.onBeginUse = ::onBeginUse;
		bombZone.onEndUse = ::onEndUse;
		bombZone.onUse = ::onUseObject;
		bombZone.onCantUse = ::onCantUse;
		bombZone.useWeapon = "briefcase_bomb_mp";
		bombZone.visuals[0].killCamEnt = spawn( "script_model", bombZone.visuals[0].origin + (0,0,128) );
	
		for ( i = 0; i < visuals.size; i++ )
		{
			if ( isDefined( visuals[i].script_exploder ) )
			{
				bombZone.exploderIndex = visuals[i].script_exploder;
				break;
			}
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
		
		bombZone.bombDefuseTrig = getent( visuals[0].target, "targetname" );
		assert( isdefined( bombZone.bombDefuseTrig ) );
		bombZone.bombDefuseTrig.origin += (0,0,-10000);
		bombZone.bombDefuseTrig.label = label;
		
		// Add spawn influencer
		dem_enemy_base_influencer_score = level.spawnsystem.dem_enemy_base_influencer_score;
		dem_enemy_base_influencer_score_curve = level.spawnsystem.dem_enemy_base_influencer_score_curve;
		dem_enemy_base_influencer_radius = level.spawnsystem.dem_enemy_base_influencer_radius;
		team_mask = maps\mp\gametypes\_spawning::get_team_mask( game["attackers"] );
		bombZone.spawnInfluencer = addsphereinfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE, 
														trigger.origin, 
														dem_enemy_base_influencer_radius, 
														dem_enemy_base_influencer_score, 
														team_mask, 
														"dem_enemy_base,r,s", 
														maps\mp\gametypes\_spawning::get_score_curve_index(dem_enemy_base_influencer_score_curve) );
	}
	
	for ( index = 0; index < level.bombZones.size; index++ )
	{
		array = [];
		for ( otherindex = 0; otherindex < level.bombZones.size; otherindex++ )
		{
			if ( otherindex != index )
				array[ array.size ] = level.bombZones[otherindex];
		}
		level.bombZones[index].otherBombZones = array;
	}
}

onBeginUse( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mpl_sd_bomb_defuse" );
		player.isDefusing = true;
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter( "sd_enemyplant", player.pers["team"] );

		bestDistance = 9000000;
		closestBomb = undefined;
		
		if ( isDefined( level.ddBombModel ) )
		{
			keys = GetArrayKeys( level.ddBombModel );
			for ( bombLabel = 0; bombLabel < keys.size; bombLabel++ )
			{
				bomb = level.ddBombModel[ keys[bombLabel] ];
				
				if ( !isDefined( bomb ) )
					continue;
				
				dist = distanceSquared( player.origin, bomb.origin );
				
				if (  dist < bestDistance )
				{
					bestDistance = dist;			
					closestBomb = bomb;
				}
			}
			
			assert( isDefined(closestBomb) );
			player.defusing = closestBomb;
			closestBomb hide();
		}
	}
	else
	{
		player.isPlanting = true;
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter( "sd_friendlyplant", player.pers["team"] );
	}
		player playSound( "fly_bomb_raise_plr" );
}

onEndUse( team, player, result )
{
	if ( !IsDefined( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;
	player notify( "event_ended" );

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( player.defusing ) && !result )
		{
			player.defusing show();
		}
	}
}

onCantUse( player )
{
	player iPrintLnBold( &"MP_CANT_PLANT_WITHOUT_BOMB" );
}

onUseObject( player )
{
	team = player.team;
  enemyTeam = getOtherTeam( team );
  
	self updateEventsPerMinute();
	player updateEventsPerMinute();

	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( team ) )
	{
		
		level thread bombPlanted( self, player );
		player logString( "bomb planted: " + self.label );
		
// removed plant audio until finalization of assest TODO : new plant sounds when assests are online
//		player playSound( "mpl_sd_bomb_plant" );
		player notify ( "bomb_planted" );
		
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_WE_PLANT", team, false, false, 5  );
	  thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_THEY_PLANT", enemyTeam, false, false, 5  );
		
		if( isdefined(player.pers["plants"]) )
		{
			player.pers["plants"]++;
			player.plants = player.pers["plants"];
		}

		if ( !isScoreBoosting( player, self ) )
		{
			player maps\mp\_medals::saboteur();
			player maps\mp\gametypes\_persistence::statAddWithGameType( "PLANTS", 1 );
			
			maps\mp\gametypes\_globallogic_score::givePlayerScore( "plant", player );
			player thread [[level.onXPEvent]]( "plant" );
		}
		
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_planted" );
	}
	else
	{
		player notify ( "bomb_defused" );
		player logString( "bomb defused: " + self.label );
		self thread bombDefused();
		self resetBombzone();
		
		if( isdefined(player.pers["defuses"]) )
		{
			player.pers["defuses"]++;
			player.defuses = player.pers["defuses"];
		}

		if ( !isScoreBoosting( player, self ) )
		{
			player maps\mp\_medals::hero();
			player maps\mp\gametypes\_persistence::statAddWithGameType( "DEFUSES", 1 );
			
			maps\mp\gametypes\_globallogic_score::givePlayerScore( "defuse", player );
		}
		
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_DEFUSED_BY", player );
	
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_WE_DEFUSE", team, false, false, 5  );
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_THEY_DEFUSE", enemyTeam, false, false, 5  );
		
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_defused" );
		
		//player thread [[level.onXPEvent]]( "defuse" );
	}
}

onDrop( player )
{
	if ( !level.bombPlanted )
	{
		if ( isDefined( player ) && isDefined( player.name ) )
			printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", game["attackers"], player );

//		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_lost", player.pers["team"] );
		if ( isDefined( player ) )
		 	player logString( "bomb dropped" );
		 else
		 	logString( "bomb dropped" );
	}

	player notify( "event_ended" );

	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
	
	maps\mp\_utility::playSoundOnPlayers( game["bomb_dropped_sound"], game["attackers"] );
}


onPickup( player )
{
	player.isBombCarrier = true;

	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );

	if ( !level.bombDefused )
	{
		if ( isDefined( player ) && isDefined( player.name ) )
			printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", game["attackers"], player );
			
		thread playSoundOnPlayers( "mus_sd_pickup"+"_"+level.teamPostfix[player.pers["team"]], player.pers["team"] );

		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_taken", player.pers["team"] );
		player logString( "bomb taken" );
	}		
	maps\mp\_utility::playSoundOnPlayers( game["bomb_recovered_sound"], game["attackers"] );
}


onReset()
{
}

bombReset( label, reason )
{
	if ( label == "_a" )
	{
		level.bombAPlanted = false;
		SetBombTimer( "A", 0 );
	}
	else 
	{
		level.bombBPlanted = false;
		SetBombTimer( "B", 0 );
	}

	setMatchFlag( "bomb_timer" + label, 0 );
	
	if ( !level.bombAPlanted && !level.bombBPlanted )
		maps\mp\gametypes\_globallogic_utils::resumeTimer();

	self.visuals[0] maps\mp\gametypes\_globallogic_utils::stopTickingSound();
}

dropBombModel( player, site )
{
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
		
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.ddBombModel[ site ] = spawn( "script_model", trace["position"] );
	level.ddBombModel[ site ].angles = dropAngles;
	level.ddBombModel[ site ] setModel( "prop_suitcase_bomb" );
}


bombPlanted( destroyedObj, player )
{
	level endon( "game_ended" );
	destroyedObj endon( "bomb_defused" );
	team = player.team;	
	game["challenge"][team]["plantedBomb"] = true;
	
	maps\mp\gametypes\_globallogic_utils::pauseTimer();
	destroyedObj.bombPlanted = true;
	
	destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic_utils::playTickingSound( "mpl_sab_ui_suitcasebomb_timer" );
	destroyedObj.tickingObject = destroyedObj.visuals[0];
	
	label = destroyedObj maps\mp\gametypes\_gameobjects::getLabel();
	
	detonateTime = int( gettime() + (level.bombTimer * 1000) );
	updateBombTimers(label, detonateTime);

	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	self dropBombModel( player, destroyedObj.label );
	destroyedObj maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	destroyedObj setUpForDefusing();
		
	player.isBombCarrier = false;
	game["challenge"][team]["plantedBomb"] = true;
	
	destroyedObj BombTimerWait(label);
	destroyedObj bombReset( label, "bomb_exploded" );
	
	if ( level.gameEnded )
	{
		return;
	}
	
	destroyedObj.bombExploded = true;	
	game["challenge"][team]["destroyedBombSite"] = true;
	explosionOrigin = destroyedObj.curorigin;
	
	level.ddBombModel[ destroyedObj.label ] Delete();
	
	if ( isdefined( player ) )
	{
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
		player maps\mp\_medals::bomber();
		player maps\mp\gametypes\_persistence::statAddWithGameType( "DESTRUCTIONS", 1 );
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_BLOWUP_BY", player );
		// give points for being the bomb destroyer for extra game mode incentive
		maps\mp\gametypes\_globallogic_score::givePlayerScore( "destroyer", player );
		player thread [[level.onXPEvent]]( "destroyer" );
	}
	else
	{
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, undefined, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
	}
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread playSoundinSpace( "mpl_sd_exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );
		
	bombZonesLeft = 0;
		
	for ( index = 0; index < level.bombZones.size; index++ )
	{
		if ( !isDefined( level.bombZones[index].bombExploded ) || !level.bombZones[index].bombExploded )
			bombZonesLeft++;
	}
		
	destroyedObj maps\mp\gametypes\_gameobjects::disableObject();
	
	if ( bombZonesLeft == 0 )
	{
		setGameEndTime( 0 );
		wait 3;
		dem_endGame( game["attackers"], game["strings"]["target_destroyed"] );
	}
	else
	{
		team = player.pers["team"];
	    enemyTeam = getOtherTeam( team );
		
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_WE_SCORE", team, false, false, 5  );
	  thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_THEY_SCORE", enemyTeam, false, false, 5  );
	    
	    //level thread play_one_left_underscore( team, enemyTeam );
		
		if( getTimeLimitDvarValue() > 0 )
		{
			level.usingExtraTime = true;
			if ( !level.hardcoreMode )
				iPrintLn( &"MP_TIME_EXTENDED" );
		}

		// remove the influencer on this object
		removeinfluencer( destroyedObj.spawnInfluencer );
		destroyedObj.spawnInfluencer = undefined;

		maps\mp\gametypes\_spawnlogic::clearSpawnPoints();			
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["attackers"], "mp_dem_spawn_attacker" );
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["defenders"], "mp_dem_spawn_defender" );
		if ( label == "_a" )
		{
			maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["attackers"], "mp_dem_spawn_attacker_a" );
			maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["defenders"], "mp_dem_spawn_defender_b" );
		}
		else
		{
			maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["attackers"], "mp_dem_spawn_attacker_b" );
			maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["defenders"], "mp_dem_spawn_defender_a" );
		}
		maps\mp\gametypes\_spawning::updateAllSpawnPoints();
	}
}

getTimeLimitDvarValue()
{
	timeLimit = maps\mp\gametypes\_globallogic_utils::getValueInRange( getDvarFloat( level.timeLimitDvar ), level.timeLimitMin, level.timeLimitMax );
	if ( level.usingExtraTime )
		return timeLimit + level.extraTime;
	return timeLimit;
}

waitLongDurationWithBombTimeUpdate( whichBomb, duration )
{
	if ( duration == 0 )
		return;
	assert( duration > 0 );
	
	starttime = gettime();
	
	endtime = gettime() + duration * 1000;
	
	while ( gettime() < endtime )
	{
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationStarts( (endtime - gettime()) / 1000 );
		
		while ( isDefined( level.hostMigrationTimer ) )
		{
			endTime += 250;
			updateBombTimers(whichBomb, endTime);
			wait 0.25;
		}
	}
	
	if( gettime() != endtime )
		println("SCRIPT WARNING: gettime() = " + gettime() + " NOT EQUAL TO endtime = " + endtime);
		
	while ( isDefined( level.hostMigrationTimer ) )
	{
		endTime += 250;
		updateBombTimers(whichBomb, endTime);
		wait 0.250;
	}
	
	return gettime() - starttime;
}

updateBombTimers(whichBomb, detonateTime)
{
	if ( whichBomb == "_a" )
	{
		level.bombAPlanted = true;
		SetBombTimer( "A", int(detonateTime) );
	}
	else
	{
		level.bombBPlanted = true;
		SetBombTimer( "B", int(detonateTime) );
	}

	setMatchFlag( "bomb_timer" + whichBomb, int(detonateTime) );
}

BombTimerWait(whichBomb)
{
	waitLongDurationWithBombTimeUpdate( whichBomb, level.bombTimer );
}

bombDefused()
{
	self.tickingObject maps\mp\gametypes\_globallogic_utils::stopTickingSound();
	self maps\mp\gametypes\_gameobjects::allowUse( "none" );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	self.bombDefused = true;
	self notify( "bomb_defused" );
	self bombReset( self.label, "bomb_defused" );
}

registerGrenadeLauncherDudDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_grenadeLauncherDudTime");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	level.grenadeLauncherDudTimeDvar = dvarString;	
	level.grenadeLauncherDudTimeMin = minValue;
	level.grenadeLauncherDudTimeMax = maxValue;
	level.grenadeLauncherDudTime = getDvarInt( level.grenadeLauncherDudTimeDvar );
}

registerThrownGrenadeDudDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_thrownGrenadeDudTime");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	level.thrownGrenadeDudTimeDvar = dvarString;	
	level.thrownGrenadeDudTimeMin = minValue;
	level.thrownGrenadeDudTimeMax = maxValue;
	level.thrownGrenadeDudTime = getDvarInt( level.thrownGrenadeDudTimeDvar );
}

play_one_left_underscore( team, enemyTeam )
{
    wait(3);
    
    if( (!IsDefined(team)) || (!IsDefined(enemyTeam)) )
    {
        return;
    }
    
    thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_ONE_LEFT_UNDERSCORE", team, false, false );
	thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "DEM_ONE_LEFT_UNDERSCORE", enemyTeam, false, false );
}

updateEventsPerMinute()
{
	if ( !isDefined( self.eventsPerMinute ) )
	{
		self.numBombEvents = 0;
		self.eventsPerMinute = 0;
	}
	
	self.numBombEvents++;
	
	minutesPassed = maps\mp\gametypes\_globallogic_utils::getTimePassed() / ( 60 * 1000 );
	
	// players use the actual time played
	if ( IsPlayer( self ) && IsDefined(self.timePlayed["total"]) )
		minutesPassed = self.timePlayed["total"] / 60;
		
	self.eventsPerMinute = self.numBombEvents / minutesPassed;
	if ( self.eventsPerMinute > self.numBombEvents )
		self.eventsPerMinute = self.numBombEvents;
}

isScoreBoosting( player, flag )
{
	if ( player.eventsPerMinute > level.playerEventsLPM )
		return true;
			
	if ( flag.eventsPerMinute > level.bombEventsLPM )
	  return true;
	  
	if ( player.numBombEvents > level.playerEventsMax )
		return true;
			
 return false;
}