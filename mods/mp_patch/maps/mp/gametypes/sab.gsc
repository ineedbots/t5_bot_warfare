#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
/*
	Sabotage
	
	// ...etc...
*/

/*QUAKED mp_sab_spawn_axis (0.75 0.0 0.5) (-16 -16 0) (16 16 72)
Axis players spawn away from enemies and near their team at one of these positions.*/

/*QUAKED mp_sab_spawn_allies (0.0 0.75 0.5) (-16 -16 0) (16 16 72)
Allied players spawn away from enemies and near their team at one of these positions.*/

/*QUAKED mp_sab_spawn_axis_start (1.0 0.0 0.5) (-16 -16 0) (16 16 72)
Axis players spawn away from enemies and near their team at one of these positions at the start of a round.*/

/*QUAKED mp_sab_spawn_allies_start (0.0 1.0 0.5) (-16 -16 0) (16 16 72)
Allied players spawn away from enemies and near their team at one of these positions at the start of a round.*/

main()
{
	if ( GetDvar( #"mapname") == "mp_background" )
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	level.teamBased = true;
	level.overrideTeamScore = true;

	maps\mp\gametypes\_globallogic_utils::registerRoundSwitchDvar( level.gameType, 0, 0, 9 );
	maps\mp\gametypes\_globallogic_utils::registerTimeLimitDvar( level.gameType, 10, 0, 1440 );
	maps\mp\gametypes\_globallogic_utils::registerScoreLimitDvar( level.gameType, 0, 0, 500 );
	maps\mp\gametypes\_globallogic_utils::registerRoundLimitDvar( level.gameType, 1, 0, 10 );
	maps\mp\gametypes\_globallogic_utils::registerNumLivesDvar( level.gameType, 0, 0, 10 );
	maps\mp\gametypes\_globallogic_utils::registerRoundWinLimitDvar( level.gameType, 0, 0, 10 );

	maps\mp\gametypes\_weapons::registerGrenadeLauncherDudDvar( level.gameType, 10, 0, 1440 );
	maps\mp\gametypes\_weapons::registerThrownGrenadeDudDvar( level.gameType, 0, 0, 1440 );
	maps\mp\gametypes\_weapons::registerKillstreakDelay( level.gameType, 0, 0, 1440 );

	maps\mp\gametypes\_globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );

	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onSpawnPlayerUnified = ::onSpawnPlayerUnified;
	level.gamemodeSpawnDvars = ::sab_gamemodeSpawnDvars;
	level.onRoundEndGame = ::onRoundEndGame;

	if ( !game["tiebreaker"] )
	{
		level.onPrecacheGameType = ::onPrecacheGameType;
		level.onTimeLimit = ::onTimeLimit;
		level.onDeadEvent = ::onDeadEvent;
		level.onRoundSwitch = ::onRoundSwitch;
		level.onPlayerKilled = ::onPlayerKilled;
	
		level.endGameOnScoreLimit = false;
		
		game["dialog"]["gametype"] = "sab_start";
		game["dialog"]["gametype_hardcore"] = "hcsab_start";
		game["dialog"]["offense_obj"] = "destroy_start";
		game["dialog"]["defense_obj"] = "destroy_start";
		game["dialog"]["sudden_death"] = "suddendeath";
		game["dialog"]["sudden_death_boost"] = "generic_boost";
	}
	else
	{
		level.onEndGame = ::onEndGame;
	
		level.endGameOnScoreLimit = false;
		
		game["dialog"]["gametype"] = "sab_start";
		game["dialog"]["gametype_hardcore"] = "hcsab_start";
		game["dialog"]["offense_obj"] = "generic_boost";
		game["dialog"]["defense_obj"] = "generic_boost";
		game["dialog"]["sudden_death"] = "suddendeath";
		game["dialog"]["sudden_death_boost"] = "generic_boost";

		maps\mp\gametypes\_globallogic_utils::registerNumLivesDvar( "tb", 1, 1, 1 );
		maps\mp\gametypes\_globallogic_utils::registerTimeLimitDvar( "tb", 0, 0, 0 );
	}

	badtrig = getent( "sab_bomb_defuse_allies", "targetname" );
	if ( isdefined( badtrig ) )
		badtrig delete();

	badtrig = getent( "sab_bomb_defuse_axis", "targetname" );
	if ( isdefined( badtrig ) )
		badtrig delete();

	level.lastDialogTime = 0;

	// Sets the scoreboard columns and determines with data is sent across the network
	setscoreboardcolumns( "kills", "deaths", "plants", "defuses" ); 
}

onPrecacheGameType()
{
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";
	
	precacheShader("waypoint_bomb");
	precacheShader("waypoint_kill");
	precacheShader("waypoint_bomb_enemy");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defuse");
	precacheShader("waypoint_target");
	precacheShader("compass_waypoint_bomb");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defuse");
	precacheShader("compass_waypoint_target");
	precacheShader("hud_suitcase_bomb");

	precacheString(&"MP_EXPLOSIVES_RECOVERED_BY");	
	precacheString(&"MP_EXPLOSIVES_RECOVERED_BY");
	precacheString(&"MP_EXPLOSIVES_DROPPED_BY");
	precacheString(&"MP_EXPLOSIVES_PLANTED_BY");
	precacheString(&"MP_EXPLOSIVES_DEFUSED_BY");
	precacheString(&"MP_YOU_HAVE_RECOVERED_THE_BOMB");
	precacheString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
	precacheString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");
	precacheString(&"MP_PLANTING_EXPLOSIVE");
	precacheString(&"MP_DEFUSING_EXPLOSIVE");
	precacheString(&"MP_TARGET_DESTROYED");
	precacheString(&"MP_NO_RESPAWN");
	precacheString(&"MP_TIE_BREAKER");	
	precacheString(&"MP_NO_RESPAWN");
	precacheString(&"MP_SUDDEN_DEATH");
}


onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		level.halftimeType = "overtime";
		level.halftimeSubCaption = &"MP_TIE_BREAKER";
		game["tiebreaker"] = true;
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}


onStartGameType()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	setClientNameMode("auto_change");
	
	game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";

	if ( !game["tiebreaker"] )
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveText( "allies", &"OBJECTIVES_SAB" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveText( "axis", &"OBJECTIVES_SAB" );
	
		if ( level.splitscreen )
		{
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_SAB" );
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_SAB" );
		}
		else
		{
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_SAB_SCORE" );
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_SAB_SCORE" );
		}
		maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( "allies", &"OBJECTIVES_SAB_HINT" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( "axis", &"OBJECTIVES_SAB_HINT" );
	}
	else
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveText( "allies", &"OBJECTIVES_TDM" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveText( "axis", &"OBJECTIVES_TDM" );
		
		if ( level.splitscreen )
		{
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_TDM" );
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_TDM" );
		}
		else
		{
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_TDM_SCORE" );
			maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_TDM_SCORE" );
		}
		maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( "allies", &"OBJECTIVES_TDM_HINT" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( "axis", &"OBJECTIVES_TDM_HINT" );
	}
	
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_sab_spawn_allies" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_sab_spawn_axis" );
	maps\mp\gametypes\_spawning::updateAllSpawnPoints();
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	spawnpoint = maps\mp\gametypes\_spawnlogic::getRandomIntermissionPoint();
	setDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );

	level.spawn_axis = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_sab_spawn_axis" );
	level.spawn_allies = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_sab_spawn_allies" );
	level.spawn_axis_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_sab_spawn_axis_start" );
	level.spawn_allies_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_sab_spawn_allies_start" );

	maps\mp\gametypes\_rank::registerScoreInfo( "plant", 500 );
	maps\mp\gametypes\_rank::registerScoreInfo( "defuse", 500 );

	allowed[0] = "sab";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	// now that the game objects have been deleted place the influencers
	maps\mp\gametypes\_spawning::create_map_placed_influencers();

	thread updateGametypeDvars();
	
	thread sabotage();
}


onTimeLimit()
{
	if ( level.inOvertime )
		return;

	thread onOvertime();
}


onOvertime()
{
	level endon ( "game_ended" );

	level.timeLimitOverride = true;
	level.inOvertime = true;
	maps\mp\gametypes\_globallogic_audio::leaderDialog( "sudden_death" );
	maps\mp\gametypes\_globallogic_audio::leaderDialog( "sudden_death_boost" );
	for ( index = 0; index < level.players.size; index++ )
	{
		level.players[index] notify("force_spawn");
		level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( &"MP_SUDDEN_DEATH", &"MP_NO_RESPAWN", undefined, (1, 0, 0), "mp_last_stand" );

		level.players[index] setClientUIVisibilityFlag( "g_compassShowEnemies", 1 );
	}

	SetMatchTalkFlag( "DeadChatWithDead", 1 );
	SetMatchTalkFlag( "DeadChatWithTeam", 0 );
	SetMatchTalkFlag( "DeadHearTeamLiving", 0 );
	SetMatchTalkFlag( "DeadHearAllLiving", 0 );
	SetMatchTalkFlag( "EveryoneHearsEveryone", 0 );

	waitTime = 0;
	while ( waitTime < 90 )
	{
		if ( !level.bombPlanted )
		{
			waitTime += 1;
			setGameEndTime( getTime() + ((90-waitTime)*1000) );
		}
		wait ( 1.0 );
	}

	thread maps\mp\gametypes\_globallogic::endGame( "tie", game["strings"]["tie"] );
}


onDeadEvent( team )
{
	if ( level.bombExploded )
		return;
		
	if ( team == "all" )
	{
		if ( level.bombPlanted )
		{
			[[level._setTeamScore]]( level.bombPlantedBy, [[level._getTeamScore]]( level.bombPlantedBy ) + 1 );
			thread maps\mp\gametypes\_globallogic::endGame( level.bombPlantedBy, game["strings"][level.bombPlantedBy+"_mission_accomplished"] );
		}
		else
		{
			thread maps\mp\gametypes\_globallogic::endGame( "tie", game["strings"]["tie"] );
		}
	}
	else if ( level.bombPlanted )
	{
		if ( team == level.bombPlantedBy )
		{
			level.plantingTeamDead = true;
			return;
		}
			
		[[level._setTeamScore]]( level.bombPlantedBy, [[level._getTeamScore]]( level.bombPlantedBy ) + 1 );
		thread maps\mp\gametypes\_globallogic::endGame( level.bombPlantedBy, game["strings"][level.otherTeam[level.bombPlantedBy]+"_eliminated"] );
	}
	else
	{
		[[level._setTeamScore]]( level.otherTeam[team], [[level._getTeamScore]]( level.otherTeam[team] ) + 1 );
		thread maps\mp\gametypes\_globallogic::endGame( level.otherTeam[team], game["strings"][team+"_eliminated"] );
	}
}

onSpawnPlayerUnified()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;

	if ( game["tiebreaker"] )
	{
		self thread maps\mp\gametypes\_hud_message::oldNotifyMessage( &"MP_TIE_BREAKER", &"MP_NO_RESPAWN", undefined, (1, 0, 0), "mp_last_stand" );
	
		hintMessage = maps\mp\gametypes\_globallogic_ui::getObjectiveHintText( self.pers["team"] );
		if ( isDefined( hintMessage ) )
			self DisplayGameModeMessage( hintMessage, "uin_alert_slideout" );
	
		self setClientUIVisibilityFlag( "g_compassShowEnemies", 1 );

		// this is being redundantly set everytime a player spawns 
		// need to move this to a once only for eveyone when tiebreaker round
		// starts
		SetMatchTalkFlag( "DeadChatWithDead", 1 );
		SetMatchTalkFlag( "DeadChatWithTeam", 0 );
		SetMatchTalkFlag( "DeadHearTeamLiving", 0 );
		SetMatchTalkFlag( "DeadHearAllLiving", 0 );
		SetMatchTalkFlag( "EveryoneHearsEveryone", 0 );
	}
	
	maps\mp\gametypes\_spawning::onSpawnPlayer_Unified();
}


onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;

	spawnteam = self.pers["team"];
	if ( game["switchedsides"] )
		spawnteam = getOtherTeam( spawnteam );

	if ( level.useStartSpawns )
	{
		if (spawnteam == "axis")
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_axis_start);
		else
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_allies_start);
	}	
	else
	{
		if (spawnteam == "axis")
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(level.spawn_axis);
		else
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(level.spawn_allies);
	}

	if ( game["tiebreaker"] )
	{
		self thread maps\mp\gametypes\_hud_message::oldNotifyMessage( &"MP_TIE_BREAKER", &"MP_NO_RESPAWN", undefined, (1, 0, 0), "mp_last_stand" );
	
		hintMessage = maps\mp\gametypes\_globallogic_ui::getObjectiveHintText( self.pers["team"] );
		if ( isDefined( hintMessage ) )
			self DisplayGameModeMessage( hintMessage, "uin_alert_slideout" );
	
		self setClientUIVisibilityFlag( "g_compassShowEnemies", 1 );
		// this is being redundantly set everytime a player spawns 
		// need to move this to a once only for eveyone when tiebreaker round
		// starts
		SetMatchTalkFlag( "DeadChatWithDead", 1 );
		SetMatchTalkFlag( "DeadChatWithTeam", 0 );
		SetMatchTalkFlag( "DeadHearTeamLiving", 0 );
		SetMatchTalkFlag( "DeadHearAllLiving", 0 );
		SetMatchTalkFlag( "EveryoneHearsEveryone", 0 );
	}

	assert( isDefined(spawnpoint) );

	self spawn( spawnpoint.origin, spawnpoint.angles, "sab" );
}


updateGametypeDvars()
{
	level.plantTime = dvarFloatValue( "planttime", 5, 0, 20 );
	level.defuseTime = dvarFloatValue( "defusetime", 5, 0, 20 );
	level.bombTimer = dvarFloatValue( "bombtimer", 45, 1, 300 );
	level.hotPotato = dvarIntValue( "hotpotato", 1, 0, 1 );
}


sabotage()
{
	level.bombPlanted = false;
	level.bombExploded = false;
		
	level._effect["bombexplosion"] = loadfx("maps/mp_maps/fx_mp_exp_bomb");

	trigger = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) ) 
	{
		error( "No sab_bomb_pickup_trig trigger found in map." );
		return;
	}

	visuals[0] = getEnt( "sab_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) ) 
	{
		error( "No sab_bomb script_model found in map." );
		return;
	}
	
	//precacheModel( "t5_weapon_briefcase_world" );	
	//visuals[0] setModel( "t5_weapon_briefcase_world" );
	level.sabBomb = maps\mp\gametypes\_gameobjects::createCarryObject( "neutral", trigger, visuals, (0,0,32) );
	level.sabBomb maps\mp\gametypes\_gameobjects::allowCarry( "any" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_bomb" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_bomb" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
	level.sabBomb maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	level.sabBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	level.sabBomb.objIDPingEnemy = true;
	level.sabBomb.onPickup = ::onPickup;
	level.sabBomb.onDrop = ::onDrop;
	level.sabBomb.allowWeapons = true;
	level.sabBomb.objPoints["allies"].archived = true;
	level.sabBomb.objPoints["axis"].archived = true;
	level.sabBomb.autoResetTime = 60.0;
	
	if ( !isDefined( getEnt( "sab_bomb_axis", "targetname" ) ) ) 
	{
		error("No sab_bomb_axis trigger found in map.");
		return;
	}
	if ( !isDefined( getEnt( "sab_bomb_allies", "targetname" ) ) )
	{
		error("No sab_bomb_allies trigger found in map.");
		return;
	}

	if ( game["switchedsides"] )
	{
		level.bombZones["allies"] = createBombZone( "allies", getEnt( "sab_bomb_axis", "targetname" ) );
		level.bombZones["axis"] = createBombZone( "axis", getEnt( "sab_bomb_allies", "targetname" ) );
	}
	else
	{
		level.bombZones["allies"] = createBombZone( "allies", getEnt( "sab_bomb_allies", "targetname" ) );
		level.bombZones["axis"] = createBombZone( "axis", getEnt( "sab_bomb_axis", "targetname" ) );
	}
}


createBombZone( team, trigger )
{
	visuals = getEntArray( trigger.target, "targetname" );
	
	bombZone = maps\mp\gametypes\_gameobjects::createUseObject( team, trigger, visuals, (0,0,64) );
	bombZone resetBombsite();
	bombZone.onUse = ::onUse;
	bombZone.onBeginUse = ::onBeginUse;
	bombZone.onEndUse = ::onEndUse;
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
	
	return bombZone;
}


onBeginUse( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player.isPlanting = true;
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter( "sd_friendlyplant", player.pers["team"] );
	}
	else
	{
		player.isDefusing = true;
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter( "sd_enemyplant", player.pers["team"] );
	}
	
	player playSound( "fly_bomb_raise_plr" );
}

onEndUse( team, player, result )
{
	if ( !isAlive( player ) )
		return;
	
	player.isPlanting = false;
	player.isDefusing = false;
	player notify( "event_ended" );
}


onPickup( player )
{
	level notify ( "bomb_picked_up" );
	
	self.autoResetTime = 60.0;
	
	level.useStartSpawns = false;
	
	team = player.pers["team"];
	
	if ( team == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";
	
	//player iPrintLnBold( &"MP_YOU_HAVE_RECOVERED_THE_BOMB" );
	player playLocalSound( "mp_suitcase_pickup" );
	player logString( "bomb taken" );
	
	excludeList[0] = player;

	if( getTime() - level.lastDialogTime > 10000 )
	{
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_acquired", team );
		player maps\mp\gametypes\_globallogic_audio::leaderDialogOnPlayer( "obj_destroy", "bomb" );


		if ( !level.splitscreen )
		{
			maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_taken", otherTeam );
			maps\mp\gametypes\_globallogic_audio::leaderDialog( "obj_defend", otherTeam );
		}

		level.lastDialogTime = getTime();
	}
	player.isBombCarrier = true;

	player maps\mp\gametypes\_persistence::statAddWithGameType( "PICKUPS", 1 );

	
	// recovered the bomb before abandonment timer elapsed
	if ( team == self maps\mp\gametypes\_gameobjects::getOwnerTeam() )
	{
		printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", team, player );
		playSoundOnPlayers( game["bomb_recovered_sound"], team );
	}
	else
	{
		printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", team, player );
//		printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", otherTeam, &"MP_THE_ENEMY" );
		playSoundOnPlayers( game["bomb_recovered_sound"] );
	}
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_kill" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
		
	level.bombZones[team] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	level.bombZones[otherTeam] maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );

	level.bombZones[otherTeam].trigger SetInvisibleToAll();
	level.bombZones[otherTeam].trigger SetVisibleToPlayer( player );
}


onDrop( player )
{
	if ( level.bombPlanted )
	{
		
	}
	else
	{
		if ( isDefined( player ) )
			printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", self maps\mp\gametypes\_gameobjects::getOwnerTeam(), player );
//		else
//			printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", self maps\mp\gametypes\_gameobjects::getOwnerTeam(), &"MP_YOUR_TEAM" );
	
		playSoundOnPlayers( game["bomb_dropped_sound"], self maps\mp\gametypes\_gameobjects::getOwnerTeam() );
		if ( isDefined( player ) )
			player logString( "bomb dropped" );
		else
			logString( "bomb dropped" );
			
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_lost", self maps\mp\gametypes\_gameobjects::getOwnerTeam() );

		player notify( "event_ended" );

		level.bombZones["axis"].trigger SetInvisibleToAll();
		level.bombZones["allies"].trigger SetInvisibleToAll();

		thread abandonmentThink( 0.0 );
	}
}


abandonmentThink( delay )
{
	level endon ( "bomb_picked_up" );
	
	wait ( delay );

	if ( isDefined( self.carrier ) )
		return;

	if ( self maps\mp\gametypes\_gameobjects::getOwnerTeam() == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";

//	printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", otherTeam, &"MP_THE_ENEMY" );
	playSoundOnPlayers( game["bomb_dropped_sound"], otherTeam );

	self maps\mp\gametypes\_gameobjects::setOwnerTeam( "neutral" );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_bomb" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_bomb" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );

	level.bombZones["allies"] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	level.bombZones["axis"] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );		
}


onUse( player )
{
	team = player.pers["team"];
	otherTeam = level.otherTeam[team];
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player notify ( "bomb_planted" );
// removed old playsound entry CDC 2/18/10
//		player playSound( "mpl_sab_bomb_plant" );
		player logString( "bomb planted" );
		
		if( isdefined(player.pers["plants"]) )
		{
			player.pers["plants"]++;
			player.plants = player.pers["plants"];
		}

		player maps\mp\_medals::saboteur();

		player maps\mp\gametypes\_persistence::statAddWithGameType( "PLANTS", 1 );
		
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_PLANTED_BY", player );
			
		//thread playSoundOnPlayers( "mus_sab_planted"+"_"+level.teamPostfix[team] );
		// Play Action music
		//maps\mp\_music::setmusicstate( "ACTION" );	
		
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_planted", team );

		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_planted", otherTeam );

		maps\mp\gametypes\_globallogic_score::givePlayerScore( "plant", player );
		//player thread [[level.onXPEvent]]( "plant" );
		
		level thread bombPlanted( self, player.pers["team"] );

		level.bombOwner = player;
		
		player.isBombCarrier = false;

//		self.keyObject maps\mp\gametypes\_gameobjects::disableObject();
		level.sabBomb.autoResetTime = undefined;
		level.sabBomb maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.sabBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		level.sabBomb maps\mp\gametypes\_gameobjects::setDropped();
		self.useWeapon = "briefcase_bomb_defuse_mp";
		
		self setUpForDefusing();
	}
	else // defused the bomb
	{
		player notify ( "bomb_defused" );
		player logString( "bomb defused" );
		
		if( isdefined(player.pers["defuses"]) )
		{
			player.pers["defuses"]++;
			player.defuses = player.pers["defuses"];
		}

		player maps\mp\_medals::hero();

		player maps\mp\gametypes\_persistence::statAddWithGameType( "DEFUSES", 1 );

		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_DEFUSED_BY", player );
		//thread playSoundOnPlayers( "mus_sab_defused"+"_"+level.teamPostfix[team] );
		maps\mp\gametypes\_globallogic_audio::set_music_on_team( "UNDERSCORE", "both", true );	
		
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_defused" );

		maps\mp\gametypes\_globallogic_score::givePlayerScore( "defuse", player );
		//player thread [[level.onXPEvent]]( "defuse" );

		level thread bombDefused( self );
		
		if ( level.inOverTime && isDefined( level.plantingTeamDead ) )
		{
			thread maps\mp\gametypes\_globallogic::endGame( player.pers["team"], game["strings"][level.bombPlantedBy+"_eliminated"] );
			return;
		}
		
		self resetBombsite();
		
		level.sabBomb maps\mp\gametypes\_gameobjects::allowCarry( "any" );
		level.sabBomb maps\mp\gametypes\_gameobjects::setPickedUp( player );
	}
}


onCantUse( player )
{
	player iPrintLnBold( &"MP_CANT_PLANT_WITHOUT_BOMB" );
}


bombPlanted( destroyedObj, team )
{
	game["challenge"][team]["plantedBomb"] = true;
	maps\mp\gametypes\_globallogic_utils::pauseTimer();
	level.bombPlanted = true;
	level.bombPlantedBy = team;
	level.timeLimitOverride = true;
	setMatchFlag( "bomb_timer", 1 );
	
	// communicate timer information to menus
	setGameEndTime( int( getTime() + (level.bombTimer * 1000) ) );
	
	destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic_utils::playTickingSound( "mpl_sab_ui_suitcasebomb_timer" );
	
	starttime = gettime();
	bombTimerWait();
	
	setMatchFlag( "bomb_timer", 0 );
	destroyedObj.visuals[0] maps\mp\gametypes\_globallogic_utils::stopTickingSound();

	if ( !level.bombPlanted )
	{
		if ( level.hotPotato )
		{
			timePassed = (gettime() - starttime) / 1000;
			level.bombTimer -= timePassed;
		}
		return;
	}
	/*
	for ( index = 0; index < level.players.size; index++ )
	{
		player = level.players[index];
		if ( player.pers["team"] == team )
			player thread maps\mp\gametypes\_hud_message::oldNotifyMessage( "Your team scored!", undefined, undefined, (0, 1, 0) );
		else if ( player.pers["team"] == level.otherTeam[team] )
			player thread maps\mp\gametypes\_hud_message::oldNotifyMessage( "Enemy team scored!", undefined, undefined, (1, 0, 0) );
	}
	*/
	explosionOrigin = level.sabBomb.visuals[0].origin+(0,0,12);
	level.bombExploded = true;	
	
	
	if ( isdefined( level.bombowner ) )
	{
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, level.bombowner, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_BLOWUP_BY", level.bombowner );
		level.bombowner maps\mp\_medals::bomber();

		level.bombowner maps\mp\gametypes\_persistence::statAddWithGameType( "DESTRUCTIONS", 1 );

	}
	else
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, undefined, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread playSoundinSpace( "mpl_sab_exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );
	
	[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + 1 );
	
	setGameEndTime( 0 );
	
	level.bombZones["allies"] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	level.bombZones["axis"] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	wait 3;
	
	// end the round without resetting the timer
	thread maps\mp\gametypes\_globallogic::endGame( team, game["strings"]["target_destroyed"] );
}

bombTimerWait()
{
	level endon("bomb_defused");
	maps\mp\gametypes\_hostmigration::waitLongDurationWithGameEndTimeUpdate( level.bombTimer );
}


resetBombsite()
{
	self maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( level.sabBomb );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	self.trigger SetInvisibleToAll();
	self.useWeapon = "briefcase_bomb_mp";
}

setUpForDefusing()
{
	self maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( undefined );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self.trigger SetVisibleToAll();
}

bombDefused( object )
{
	setMatchFlag( "bomb_timer", 0 );
	maps\mp\gametypes\_globallogic_utils::resumeTimer();
	level.bombPlanted = false;
	if ( !level.inOvertime )
		level.timeLimitOverride = false;

	level notify("bomb_defused");	
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{	
	inBombZone = false;
	inBombZoneTeam = "none";
	
	if ( isdefined( sWeapon ) && maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) )
		return;
	
	if ( isdefined( level.bombZones["allies"] ) )
	{
		dist = Distance2d(self.origin, level.bombZones["allies"].curorigin);
		if ( dist < level.defaultOffenseRadius )
		{
			inBombZoneTeam = "allies";
			inBombZone = true;
		}
	}
	if ( isdefined( level.bombZones["axis"] ) )
	{
		dist = Distance2d(self.origin, level.bombZones["axis"].curorigin);
		if ( dist < level.defaultOffenseRadius )
		{
			inBombZoneTeam = "axis";
			inBombZone = true;
		}
	}
	
	if ( inBombZone && isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] )
	{	
		if ( inBombZoneTeam == self.pers["team"] )
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
	
	if ( isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] && isdefined( self.isBombCarrier ) && self.isBombCarrier == true )
		attacker maps\mp\_challenges::killedBombCarrier();
}

onEndGame( winningTeam )
{
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
}

onRoundEndGame( roundWinner )
{
	if ( game["roundswon"]["allies"] == game["roundswon"]["axis"] )
		winner = "tie";
	else if ( game["roundswon"]["axis"] > game["roundswon"]["allies"] )
		winner = "axis";
	else
		winner = "allies";
	
	return winner;
}

sab_gamemodeSpawnDvars(reset_dvars)
{
	ss = level.spawnsystem;

	// sabotage: influencer around friendly base
	ss.sab_friendly_base_influencer_score =	set_dvar_float_if_unset("scr_spawn_sab_friendly_base_influencer_score", "100", reset_dvars);
	ss.sab_friendly_base_influencer_score_curve =	set_dvar_if_unset("scr_spawn_sab_friendly_base_influencer_score_curve", "constant", reset_dvars);
	ss.sab_friendly_base_influencer_radius =	set_dvar_float_if_unset("scr_spawn_sab_friendly_base_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
	
	// sabotage: influencer around enemy base
	ss.sab_enemy_base_influencer_score =	set_dvar_float_if_unset("scr_spawn_sab_enemy_base_influencer_score", "-500", reset_dvars);
	ss.sab_enemy_base_influencer_score_curve =	set_dvar_if_unset("scr_spawn_sab_enemy_base_influencer_score_curve", "constant", reset_dvars);
	ss.sab_enemy_base_influencer_radius =	set_dvar_float_if_unset("scr_spawn_sab_enemy_base_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
	
	// sabotage: negative influencer around carrier
	ss.sab_carrier_influencer_score =	set_dvar_float_if_unset("scr_spawn_sab_carrier_influencer_score", "-75", reset_dvars);
	ss.sab_carrier_influencer_score_curve =	set_dvar_if_unset("scr_spawn_sab_carrier_influencer_score_curve", "linear", reset_dvars);
	ss.sab_carrier_influencer_radius =	set_dvar_float_if_unset("scr_spawn_sab_carrier_influencer_radius", "" + 8.0*get_player_height(), reset_dvars);
	
}
