#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if ( GetDvar( #"mapname") == "mp_background" )
		return;

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	maps\mp\gametypes\_globallogic_utils::registerTimeLimitDvar( level.gameType, 30, 0, 1440 );
	maps\mp\gametypes\_globallogic_utils::registerScoreLimitDvar( level.gameType, 300, 0, 1000 );
	maps\mp\gametypes\_globallogic_utils::registerNumLivesDvar( level.gameType, 0, 0, 10 );

	maps\mp\gametypes\_weapons::registerGrenadeLauncherDudDvar( level.gameType, 10, 0, 1440 );
	maps\mp\gametypes\_weapons::registerThrownGrenadeDudDvar( level.gameType, 0, 0, 1440 );
	maps\mp\gametypes\_weapons::registerKillstreakDelay( level.gameType, 0, 0, 1440 );

	maps\mp\gametypes\_globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );
	
	level.teamBased = true;
	level.doPrematch = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onSpawnPlayerUnified = ::onSpawnPlayerUnified;
	level.playerSpawnedCB = ::koth_playerSpawnedCB;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onEndGame= ::onEndGame;
	level.gamemodeSpawnDvars = ::koth_gamemodeSpawnDvars;

	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );

	precacheShader( "waypoint_targetneutral" );
	precacheShader( "waypoint_captureneutral" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	
	precacheString( &"MP_WAITING_FOR_HQ" );
	
	if ( GetDvar( #"koth_autodestroytime") == "" )
		setdvar("koth_autodestroytime", "60");
	level.hqAutoDestroyTime = GetDvarInt( #"koth_autodestroytime");
	
	if ( GetDvar( #"koth_spawntime") == "" )
		setdvar("koth_spawntime", "45");
	level.hqSpawnTime = GetDvarInt( #"koth_spawntime");
	
	if ( GetDvar( #"koth_kothmode") == "" )
		setdvar("koth_kothmode", "1");
	level.kothMode = GetDvarInt( #"koth_kothmode");

	if ( GetDvar( #"koth_captureTime") == "" )
		setdvar("koth_captureTime", "20");
	level.captureTime = GetDvarInt( #"koth_captureTime");

	if ( GetDvar( #"koth_destroyTime") == "" )
		setdvar("koth_destroyTime", "10");
	level.destroyTime = GetDvarInt( #"koth_destroyTime");
	
	if ( GetDvar( #"koth_delayPlayer") == "" )
		setdvar("koth_delayPlayer", 1);
	level.delayPlayer = GetDvarInt( #"koth_delayPlayer");

	if ( GetDvar( #"koth_spawnDelay") == "" )
		setdvar("koth_spawnDelay", 0);
	level.spawnDelay = GetDvarInt( #"koth_spawnDelay");
		
	level.iconoffset = (0,0,32);
	
	level.onRespawnDelay = ::getRespawnDelay;

	game["dialog"]["gametype"] = "hq_start";
	game["dialog"]["gametype_hardcore"] = "hchq_start";
	//game["dialog"]["neutral_obj"] = "cap_start";
	game["dialog"]["offense_obj"] = "cap_start";
	game["dialog"]["defense_obj"] = "cap_start";
	//game["dialog"]["hq_defend"] = "hq_defend";

	level.lastDialogTime = 0;
	
	// Sets the scoreboard columns and determines with data is sent across the network
	setscoreboardcolumns( "kills", "deaths", "captures", "defends" ); 
}


updateObjectiveHintMessages( alliesObjective, axisObjective )
{
	game["strings"]["objective_hint_allies"] = alliesObjective;
	game["strings"]["objective_hint_axis"  ] = axisObjective;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( isDefined( player.pers["team"] ) && player.pers["team"] != "spectator" )
		{
			hintText = maps\mp\gametypes\_globallogic_ui::getObjectiveHintText( player.pers["team"] );
			player DisplayGameModeMessage( hintText, "uin_alert_slideout" );
		}
	}
}


getRespawnDelay()
{
	self.lowerMessageOverride = undefined;

	if ( !isDefined( level.radio.gameobject ) )
		return undefined;
	
	hqOwningTeam = level.radio.gameobject maps\mp\gametypes\_gameobjects::getOwnerTeam();
	if ( self.pers["team"] == hqOwningTeam )
	{
		if ( !isDefined( level.hqDestroyTime ) )
			return undefined;
		
		timeRemaining = (level.hqDestroyTime - gettime()) / 1000;

		if (!level.spawnDelay )
			return undefined;

		if ( level.spawnDelay >= level.hqAutoDestroyTime )
			self.lowerMessageOverride = &"MP_WAITING_FOR_HQ";				
			
		if ( level.delayPlayer )
		{
			return min( level.spawnDelay, timeRemaining );
		}
		else
		{
			return int(timeRemaining);
		}
	}
}


onStartGameType()
{
	// TODO: HQ objective text
	maps\mp\gametypes\_globallogic_ui::setObjectiveText( "allies", &"OBJECTIVES_KOTH" );
	maps\mp\gametypes\_globallogic_ui::setObjectiveText( "axis", &"OBJECTIVES_KOTH" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_KOTH" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_KOTH" );
	}
	else
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_KOTH_SCORE" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_KOTH_SCORE" );
	}
	
	level.objectiveHintPrepareHQ = &"MP_CONTROL_HQ";
	level.objectiveHintCaptureHQ = &"MP_CAPTURE_HQ";
	level.objectiveHintDestroyHQ = &"MP_DESTROY_HQ";
	level.objectiveHintDefendHQ = &"MP_DEFEND_HQ";
	precacheString( level.objectiveHintPrepareHQ );
	precacheString( level.objectiveHintCaptureHQ );
	precacheString( level.objectiveHintDestroyHQ );
	precacheString( level.objectiveHintDefendHQ );
	
	if ( level.kothmode )
		level.objectiveHintDestroyHQ = level.objectiveHintCaptureHQ;
	
	if ( level.hqSpawnTime )
		updateObjectiveHintMessages( level.objectiveHintPrepareHQ, level.objectiveHintPrepareHQ );
	else
		updateObjectiveHintMessages( level.objectiveHintCaptureHQ, level.objectiveHintCaptureHQ );
	
	setClientNameMode("auto_change");
	
	// TODO: HQ spawnpoints
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawning::updateAllSpawnPoints();
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	spawnpoint = maps\mp\gametypes\_spawnlogic::getRandomIntermissionPoint();
	setDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );
	
	level.spawn_all = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_tdm_spawn" );
	if ( !level.spawn_all.size )
	{
		println("^1No mp_tdm_spawn spawnpoints in level!");
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}
	
	// use the new spawn logic from the start
	level.useStartSpawns = false;
	
	allowed[0] = "hq";

	if ( level.script == "mp_kowloon" )
	{
		allowed[1] = "koth";
	}

	maps\mp\gametypes\_gameobjects::main(allowed);
	
	// now that the game objects have been deleted place the influencers
	maps\mp\gametypes\_spawning::create_map_placed_influencers();

	thread SetupRadios();

	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_75", 40 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_50", 30 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_25", 20 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 10 );
	maps\mp\gametypes\_rank::registerScoreInfo( "defend", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assault", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "capture", 150 );
	
	thread HQMainLoop();
}

spawn_first_radio(delay)
{
	// pick next HQ object
	level.radio= PickRandomRadioToSpawn();
	logString("radio spawned: ("+level.radio.trigOrigin[0]+","+level.radio.trigOrigin[1]+","+level.radio.trigOrigin[2]+")");
	
	level.radio enable_radio_spawn_influencer(true);
	
	//thread enable_initial_spawn_influencers( 20 );
	
	return;
}

spawn_next_radio()
{
	// pick next HQ object
	level.radio= PickRadioToSpawn();
	logString("radio spawned: ("+level.radio.trigOrigin[0]+","+level.radio.trigOrigin[1]+","+level.radio.trigOrigin[2]+")");
	
	level.radio enable_radio_spawn_influencer(true);
	
	return;
}

HQMainLoop()
{
	level endon("game_ended");
	
	level.hqRevealTime = -100000;
	
	hqSpawningInStr = &"MP_HQ_AVAILABLE_IN";
	if ( level.kothmode )
	{
		hqDestroyedInFriendlyStr = &"MP_HQ_DESPAWN_IN";
		hqDestroyedInEnemyStr = &"MP_HQ_DESPAWN_IN";
	}
	else
	{
		hqDestroyedInFriendlyStr = &"MP_HQ_REINFORCEMENTS_IN";
		hqDestroyedInEnemyStr = &"MP_HQ_DESPAWN_IN";
	}
	
	precacheString( hqSpawningInStr );
	precacheString( hqDestroyedInFriendlyStr );
	precacheString( hqDestroyedInEnemyStr );
	precacheString( &"MP_CAPTURING_HQ" );
	precacheString( &"MP_DESTROYING_HQ" );
	
	spawn_first_radio();
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
	
	wait 5;
		
	timerDisplay = [];
	timerDisplay["allies"] = createServerTimer( "objective", 1.4, "allies" );
	timerDisplay["allies"] setPoint( "TOPRIGHT", "TOPRIGHT", 0, 0 );
	timerDisplay["allies"].label = hqSpawningInStr;
	timerDisplay["allies"].alpha = 0;
	timerDisplay["allies"].archived = false;
	timerDisplay["allies"].hideWhenInMenu = true;
	
	timerDisplay["axis"  ] = createServerTimer( "objective", 1.4, "axis" );
	timerDisplay["axis"  ] setPoint( "TOPRIGHT", "TOPRIGHT", 0, 0 );
	timerDisplay["axis"  ].label = hqSpawningInStr;
	timerDisplay["axis"  ].alpha = 0;
	timerDisplay["axis"  ].archived = false;
	timerDisplay["axis"  ].hideWhenInMenu = true;
	
	thread hideTimerDisplayOnGameEnd( timerDisplay["allies"] );
	thread hideTimerDisplayOnGameEnd( timerDisplay["axis"  ] );
	
	locationObjID = maps\mp\gametypes\_gameobjects::getNextObjID();
	
	objective_add( locationObjID, "invisible", (0,0,0) );
	
	while( 1 )
	{
		iPrintLn( &"MP_HQ_REVEALED" );
		playSoundOnPlayers( "mp_suitcase_pickup" );
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_located" );
//		maps\mp\gametypes\_globallogic_audio::leaderDialog( "move_to_new" );
		
		level.radio.gameobject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
		
		level.hqRevealTime = gettime();
		
		maps\mp\_rcbomb::detonateAllIfTouchingSphere(level.radio.origin, 75);
	
		if ( level.hqSpawnTime )
		{
			nextObjPoint = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", level.radio.origin + level.iconoffset, "all", "waypoint_targetneutral" );
			nextObjPoint setWayPoint( true, "waypoint_targetneutral" );
			objective_position( locationObjID, level.radio.trigorigin );
			objective_icon( locationObjID, "waypoint_targetneutral" );
			objective_state( locationObjID, "active" );

			updateObjectiveHintMessages( level.objectiveHintPrepareHQ, level.objectiveHintPrepareHQ );
			
			timerDisplay["allies"].label = hqSpawningInStr;
			timerDisplay["allies"] setTimer( level.hqSpawnTime );
			timerDisplay["allies"].alpha = 1;
			timerDisplay["axis"  ].label = hqSpawningInStr;
			timerDisplay["axis"  ] setTimer( level.hqSpawnTime );
			timerDisplay["axis"  ].alpha = 1;

			wait level.hqSpawnTime;

			maps\mp\gametypes\_objpoints::deleteObjPoint( nextObjPoint );
			objective_state( locationObjID, "invisible" );
			maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_online" );
		}

		timerDisplay["allies"].alpha = 0;
		timerDisplay["axis"  ].alpha = 0;
		
		waittillframeend;
		
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "obj_capture" );
		updateObjectiveHintMessages( level.objectiveHintCaptureHQ, level.objectiveHintCaptureHQ );
		playSoundOnPlayers( "mpl_hq_cap_us" );

		level.radio.gameobject maps\mp\gametypes\_gameobjects::enableObject();
		
		level.radio.gameobject maps\mp\gametypes\_gameobjects::allowUse( "any" );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::setUseTime( level.captureTime );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_HQ" );
		
		objective_icon( locationObjID, "compass_waypoint_captureneutral" );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_captureneutral" );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_captureneutral" );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
		
		level.radio.gameobject.onUse = ::onRadioCapture;
		level.radio.gameobject.onBeginUse = ::onBeginUse;
		level.radio.gameobject.onEndUse = ::onEndUse;
		
		level waittill( "hq_captured" );
		
		ownerTeam = level.radio.gameobject maps\mp\gametypes\_gameobjects::getOwnerTeam();
		otherTeam = getOtherTeam( ownerTeam );
		
		if ( level.hqAutoDestroyTime )
		{
			thread DestroyHQAfterTime( level.hqAutoDestroyTime );
			timerDisplay[ownerTeam] setTimer( level.hqAutoDestroyTime );
			timerDisplay[otherTeam] setTimer( level.hqAutoDestroyTime );
		}
		else
		{
			level.hqDestroyedByTimer = false;
		}
		
		while( 1 )
		{
			ownerTeam = level.radio.gameobject maps\mp\gametypes\_gameobjects::getOwnerTeam();
			otherTeam = getOtherTeam( ownerTeam );
	
			if ( ownerTeam == "allies" )
			{
				updateObjectiveHintMessages( level.objectiveHintDefendHQ, level.objectiveHintDestroyHQ );
			}
			else
			{
				updateObjectiveHintMessages( level.objectiveHintDestroyHQ, level.objectiveHintDefendHQ );
			}
	
			level.radio.gameobject maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			level.radio.gameobject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
			level.radio.gameobject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
			level.radio.gameobject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
			level.radio.gameobject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );

			if ( !level.kothMode )
				level.radio.gameobject maps\mp\gametypes\_gameobjects::setUseText( &"MP_DESTROYING_HQ" );
			
			level.radio.gameobject.onUse = ::onRadioDestroy;
			
			if ( level.hqAutoDestroyTime )
			{
				timerDisplay[ownerTeam].label = hqDestroyedInFriendlyStr;
				if ( !level.splitscreen )
					timerDisplay[ownerTeam].alpha = 1;
				timerDisplay[otherTeam].label = hqDestroyedInEnemyStr;
				if ( !level.splitscreen )
					timerDisplay[otherTeam].alpha = 1;
			}
			
			level thread dropAllAroundHQ();
			
			level waittill( "hq_destroyed" );
			
			level.radio enable_radio_spawn_influencer(false);

			if ( !level.kothmode || level.hqDestroyedByTimer )
				break;
			
			thread forceSpawnTeam( ownerTeam );
			
			level.radio.gameobject maps\mp\gametypes\_gameobjects::setOwnerTeam( getOtherTeam( ownerTeam ) );
		}
		
		level.radio.gameobject maps\mp\gametypes\_gameobjects::disableObject();
		level.radio.gameobject maps\mp\gametypes\_gameobjects::allowUse( "none" );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::setOwnerTeam( "neutral" );
		level.radio.gameobject maps\mp\gametypes\_gameobjects::setModelVisibility( false );
		
		level notify("hq_reset");
		
		timerDisplay["allies"].alpha = 0;
		timerDisplay["axis"  ].alpha = 0;
		
		spawn_next_radio();
		
		wait .05;
		
		thread forceSpawnTeam( ownerTeam );
		
		wait 3.0;
	}
}


hideTimerDisplayOnGameEnd( timerDisplay )
{
	level waittill("game_ended");
	timerDisplay.alpha = 0;
}


forceSpawnTeam( team )
{
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( !isdefined( player ) )
			continue;
		
		if ( player.pers["team"] == team )
		{
			player notify( "force_spawn" );
			wait .1;
		}
	}
}


onBeginUse( player )
{
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();

	if ( ownerTeam == "neutral" )
	{
		self.objPoints[player.pers["team"]] thread maps\mp\gametypes\_objpoints::startFlashing();
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter( "hq_protect", player.pers["team"] );
	}
	else
	{
		self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::startFlashing();
		self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::startFlashing();
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter( "hq_attack", player.pers["team"] );
	}
}


onEndUse( team, player, success )
{
	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	player notify( "event_ended" );
}


onRadioCapture( player )
{
	team = player.pers["team"];

	player logString( "radio captured" );

	string = &"MP_HQ_CAPTURED_BY";
	thread give_capture_credit( self.touchList[team], string );

	oldTeam = maps\mp\gametypes\_gameobjects::getOwnerTeam();
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	if ( !level.kothMode )
		self maps\mp\gametypes\_gameobjects::setUseTime( level.destroyTime );
	
	otherTeam = "axis";
	if ( team == "axis" )
		otherTeam = "allies";
	
	thread printOnTeamArg( &"MP_HQ_CAPTURED_BY", team, player );
	thread printOnTeam( &"MP_HQ_CAPTURED_BY_ENEMY", otherTeam );
	maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_secured", team );
	//maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_defend", team );
	maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_enemy_captured", otherTeam );
	thread playSoundOnPlayers( "mp_war_objective_taken", team );
	thread playSoundOnPlayers( "mp_war_objective_lost", otherTeam );
	//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "CTF_WE_TAKE", Team, false, true, 5 );
	//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "CTF_THEY_TAKE", otherTeam, false, true, 5 );	
	
	level thread awardHQPoints( team );
	
	level notify( "hq_captured" );
	player notify( "event_ended" );
}

give_capture_credit( touchList, string )
{
	wait .05;
	maps\mp\gametypes\_globallogic_utils::WaitTillSlowProcessAllowed();

	players = getArrayKeys( touchList );
	for ( i = 0; i < players.size; i++ )
	{
		player_from_touchlist = touchList[players[i]].player;
		maps\mp\gametypes\_globallogic_score::givePlayerScore( "capture", player_from_touchlist );

		level thread maps\mp\_popups::DisplayTeamMessageToAll( string, player_from_touchlist );

		if( isdefined(player_from_touchlist.pers["captures"]) )
		{
			player_from_touchlist.pers["captures"]++;
			player_from_touchlist.captures = player_from_touchlist.pers["captures"];
		}

		player_from_touchlist maps\mp\_medals::positionSecure();
		player_from_touchlist maps\mp\gametypes\_persistence::statAddWithGameType( "CAPTURES", 1 );

		if ( isdefined( player_from_touchlist.thisPlayerIsInLastStand ) && player_from_touchlist.thisPlayerIsInLastStand == true )
			player_from_touchlist maps\mp\_medals::heroic();
	}
}

dropAllAroundHQ( radio )
{
	origin = level.radio.origin;
	level waittill( "hq_reset" );
	dropAllToGround( origin, 100, 50 );
}

onRadioDestroy( player )
{
	team = player.pers["team"];
	otherTeam = "axis";
	if ( team == "axis" )
		otherTeam = "allies";

	player logString( "radio destroyed" );
	player thread [[level.onXPEvent]]( "capture" );
	maps\mp\gametypes\_globallogic_score::givePlayerScore( "capture", player );	
	player maps\mp\gametypes\_persistence::statAddWithGameType( "DESTRUCTIONS", 1 );
		
	if( isdefined(player.pers["destructions"]) )
	{
		player.pers["destructions"]++;
		player.destructions = player.pers["destructions"];
	}
	
	level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_HQ_DESTROYED_BY", player );

	if ( level.kothmode )
	{
		thread printOnTeamArg( &"MP_HQ_CAPTURED_BY", team, player );
		thread printOnTeam( &"MP_HQ_CAPTURED_BY_ENEMY", otherTeam );
		//thread playSoundOnPlayers( "mus_hq_captured"+"_"+level.teamPostfix[team] );
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_secured", team );
		//maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_defend", team );
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_enemy_destroyed", otherTeam );
		//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "CTF_WE_TAKE", Team, false, true, 5 );
		//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "CTF_THEY_TAKE", otherTeam, false, true, 5 );			
	}
	else
	{
		thread printOnTeamArg( &"MP_HQ_DESTROYED_BY", team, player );
		thread printOnTeam( &"MP_HQ_DESTROYED_BY_ENEMY", otherTeam );
		//thread playSoundOnPlayers( "mus_hq_captured"+"_"+level.teamPostfix[team] );
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_secured", team );
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_enemy_destroyed", otherTeam );
		//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "CTF_WE_TAKE", Team, false, true, 5 );
		//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "CTF_THEY_TAKE", otherTeam, false, true, 5 );			
	}

	//thread playSoundOnPlayers( "mp_war_objective_taken", team );
	//thread playSoundOnPlayers( "mp_war_objective_lost", otherTeam );
	
	level notify( "hq_destroyed" );
	
	if ( level.kothmode )
		level thread awardHQPoints( team );

	player notify( "event_ended" );
}


DestroyHQAfterTime( time )
{
	level endon( "game_ended" );
	level endon( "hq_reset" );
	
	level.hqDestroyTime = gettime() + time * 1000;
	level.hqDestroyedByTimer = false;
	
	wait time;

	maps\mp\gametypes\_globallogic_audio::leaderDialog( "hq_offline" );

	level.hqDestroyedByTimer = true;

	level notify( "hq_destroyed" );
}


awardHQPoints( team )
{
	level endon( "game_ended" );
	level endon( "hq_destroyed" );
	
	level notify("awardHQPointsRunning");
	level endon("awardHQPointsRunning");
	
	seconds = 5;
	
	while ( !level.gameEnded )
	{
		[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + seconds );
		for ( index = 0; index < level.players.size; index++ )
		{
			player = level.players[index];
			
			if ( player.pers["team"] == team )
			{
				player thread [[level.onXPEvent]]( "defend" );
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "defend", player );	
			}
		}
		
		wait seconds;
	}
}


onSpawnPlayerUnified()
{
	maps\mp\gametypes\_spawning::onSpawnPlayer_Unified();
}

onSpawnPlayer()
{
	spawnpoint = undefined;
	
	if (IsDefined(level.radio))
	{
		if (IsDefined(level.radio.gameobject))
		{
			hqOwningTeam = level.radio.gameobject maps\mp\gametypes\_gameobjects::getOwnerTeam();
			if ( self.pers["team"] == hqOwningTeam )
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, level.radio.gameobject.nearSpawns );
			else if ( level.spawnDelay >= level.hqAutoDestroyTime && gettime() > level.hqRevealTime + 10000 )
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all );
			else
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, level.radio.gameobject.outerSpawns );
		}
	}
	
	if ( !isDefined( spawnpoint ) )
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all );
	
	assert( isDefined(spawnpoint) );
	
	self spawn( spawnpoint.origin, spawnpoint.angles, "koth" );
}


koth_playerSpawnedCB()
{
	self.lowerMessageOverride = undefined;
}


SetupRadios()
{
	maperrors = [];

	radios = getentarray( "hq_hardpoint", "targetname" );
	
	if ( radios.size < 2 )
	{
		maperrors[maperrors.size] = "There are not at least 2 entities with targetname \"radio\"";
	}
	
	trigs = getentarray("radiotrigger", "targetname");
	for ( i = 0; i < radios.size; i++ )
	{
		errored = false;
		
		radio = radios[i];
		radio.trig = undefined;
		for ( j = 0; j < trigs.size; j++ )
		{
			if ( radio istouching( trigs[j] ) )
			{
				if ( isdefined( radio.trig ) )
				{
					maperrors[maperrors.size] = "Radio at " + radio.origin + " is touching more than one \"radiotrigger\" trigger";
					errored = true;
					break;
				}
				radio.trig = trigs[j];
				break;
			}
		}
		
		if ( !isdefined( radio.trig ) )
		{
			if ( !errored )
			{
				maperrors[maperrors.size] = "Radio at " + radio.origin + " is not inside any \"radiotrigger\" trigger";
				continue;
			}
			
			// possible fallback (has been tested)
			//radio.trig = spawn( "trigger_radius", radio.origin, 0, 128, 128 );
			//errored = false;
		}
		
		assert( !errored );
		
		radio.trigorigin = radio.trig.origin;
		
		visuals = [];
		visuals[0] = radio;
		
		otherVisuals = getEntArray( radio.target, "targetname" );
		for ( j = 0; j < otherVisuals.size; j++ )
		{
			visuals[visuals.size] = otherVisuals[j];
		}
		
		radio.gameObject = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", radio.trig, visuals, (radio.origin - radio.trigorigin) + level.iconoffset );
		radio.gameObject maps\mp\gametypes\_gameobjects::disableObject();
		radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( false );
		radio.trig.useObj = radio.gameObject;
		
		radio setUpNearbySpawns();
		radio createRadioSpawnInfluencer();
	}
	
	if (maperrors.size > 0)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");
		
		maps\mp\_utility::error("Map errors. See above");
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		
		return;
	}
	
	level.radios = radios;
	
	level.prevradio = undefined;
	level.prevradio2 = undefined;
	
	return true;
}

setUpNearbySpawns()
{
	spawns = level.spawn_all;
	
	for ( i = 0; i < spawns.size; i++ )
	{
		spawns[i].distsq = distanceSquared( spawns[i].origin, self.origin );
	}
	
	// sort by distsq
	for ( i = 1; i < spawns.size; i++ )
	{
		thespawn = spawns[i];
		for ( j = i - 1; j >= 0 && thespawn.distsq < spawns[j].distsq; j-- )
			spawns[j + 1] = spawns[j];
		spawns[j + 1] = thespawn;
	}
	
	first = [];
	second = [];
	third = [];
	outer = [];
	
	thirdSize = spawns.size / 3;
	for ( i = 0; i <= thirdSize; i++ )
	{
		first[ first.size ] = spawns[i];
	}
	for ( ; i < spawns.size; i++ )
	{
		outer[ outer.size ] = spawns[i];
		if ( i <= (thirdSize*2) )
			second[ second.size ] = spawns[i];
		else			
			third[ third.size ] = spawns[i];
	}
	
	self.gameObject.nearSpawns = first;
	self.gameObject.midSpawns = second;
	self.gameObject.farSpawns = third;
	self.gameObject.outerSpawns = outer;
}

PickRandomRadioToSpawn()
{
	radio = level.radios[ randomint( level.radios.size) ];
	level.prevradio2 = level.prevradio;
	level.prevradio = radio;
	
	return radio;
}

PickRadioToSpawn()
{
	// find average of positions of each team
	// (medians would be better, to get rid of outliers...)
	// and find the radio which has the least difference in distance from those two averages
	
	avgpos["allies"] = (0,0,0);
	avgpos["axis"] = (0,0,0);
	num["allies"] = 0;
	num["axis"] = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( isalive( player ) )
		{
			avgpos[ player.pers["team"] ] += player.origin;
			num[ player.pers["team"] ]++;
		}
	}
	
	if ( num["allies"] == 0 || num["axis"] == 0 )
	{
		radio = level.radios[ randomint( level.radios.size) ];
		while ( isDefined( level.prevradio ) && radio == level.prevradio ) // so lazy
			radio = level.radios[ randomint( level.radios.size) ];
		
		level.prevradio2 = level.prevradio;
		level.prevradio = radio;
		
		return radio;
	}
	
	avgpos["allies"] = avgpos["allies"] / num["allies"];
	avgpos["axis"  ] = avgpos["axis"  ] / num["axis"  ];
	
	bestradio = undefined;
	lowestcost = undefined;
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		// (purposefully using distance instead of distanceSquared)
		cost = abs( distance( radio.origin, avgpos["allies"] ) - distance( radio.origin, avgpos["axis"] ) );
		
		if ( isdefined( level.prevradio ) && radio == level.prevradio )
		{
			continue;
		}
		if ( isdefined( level.prevradio2 ) && radio == level.prevradio2 )
		{
			if ( level.radios.size > 2 )
				continue;
			else
				cost += 512;
		}
		
		if ( !isdefined( lowestcost ) || cost < lowestcost )
		{
			lowestcost = cost;
			bestradio = radio;
		}
	}
	assert( isdefined( bestradio ) );
	
	level.prevradio2 = level.prevradio;
	level.prevradio = bestradio;
	
	return bestradio;
}



onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( !isPlayer( attacker ) || (!self.touchTriggers.size && !attacker.touchTriggers.size) || attacker.pers["team"] == self.pers["team"] )
		return;

	medalGiven = false;

	if ( self.touchTriggers.size )
	{
		triggerIds = getArrayKeys( self.touchTriggers );
		ownerTeam = self.touchTriggers[triggerIds[0]].useObj.ownerTeam;
		
		if ( ownerTeam != "neutral" )
		{
			team = self.pers["team"];
			if ( team == ownerTeam )
			{
				attacker thread [[level.onXPEvent]]( "assault" );
				if ( !medalGiven && !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) ) 
				{
					attacker maps\mp\_medals::offense( sWeapon );
					attacker maps\mp\gametypes\_persistence::statAddWithGameType( "OFFENDS", 1 );
					
					medalGiven = true;
				}
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "assault", attacker );
			}
			else
			{
				attacker thread [[level.onXPEvent]]( "defend" );
				if ( !medalGiven && !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon )  ) 
				{
					if( isdefined(attacker.pers["defends"]) )
					{
						attacker.pers["defends"]++;
						attacker.defends = attacker.pers["defends"];
					}

					attacker maps\mp\_medals::defense( sWeapon );
					medalGiven = true;
					attacker maps\mp\gametypes\_persistence::statAddWithGameType( "DEFENDS", 1 );
				}
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "defend", attacker );
			}
		}		
	}	
	
	if ( attacker.touchTriggers.size )
	{
		triggerIds = getArrayKeys( attacker.touchTriggers );
		ownerTeam = attacker.touchTriggers[triggerIds[0]].useObj.ownerTeam;
		
		if ( ownerTeam != "neutral" )
		{
			team = attacker.pers["team"];
			if ( team == ownerTeam )
			{
				attacker thread [[level.onXPEvent]]( "defend" );
				if ( !medalGiven && !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon )  ) 
				{					
					if( isdefined(attacker.pers["defends"]) )
					{
						attacker.pers["defends"]++;
						attacker.defends = attacker.pers["defends"];
					}

					attacker maps\mp\_medals::defense( sWeapon );
					medalGiven = true;
					attacker maps\mp\gametypes\_persistence::statAddWithGameType( "DEFENDS", 1 );
				}
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "defend", attacker );
			}
			else
			{
				attacker thread [[level.onXPEvent]]( "assault" );
				if ( !medalGiven && !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon )  ) 
				{
					attacker maps\mp\_medals::offense( sWeapon );
					medalGiven = true;
					attacker maps\mp\gametypes\_persistence::statAddWithGameType( "OFFENDS", 1 );
				}
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "assault", attacker );
			}		
		}
	}
}

onEndGame( winningTeam )
{
	for ( i = 0; i < level.radios.size; i++ )
	{
		level.radios[i].gameobject maps\mp\gametypes\_gameobjects::allowUse( "none" );
	}
}

createRadioSpawnInfluencer()
{
	koth_objective_influencer_score= level.spawnsystem.koth_objective_influencer_score;
	koth_objective_influencer_score_curve= level.spawnsystem.koth_objective_influencer_score_curve;
	koth_objective_influencer_radius= level.spawnsystem.koth_objective_influencer_radius;
	
		// this affects both teams
	self.spawn_influencer = addsphereinfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
							 self.gameobject.curOrigin, 
							 koth_objective_influencer_radius,
							 koth_objective_influencer_score,
							 0,
							 "koth_objective,r,s",
							 maps\mp\gametypes\_spawning::get_score_curve_index(koth_objective_influencer_score_curve) );

	// turn it off for now
	self enable_radio_spawn_influencer(false);
}

enable_radio_spawn_influencer( enabled )
{
	if ( isdefined(self.spawn_influencer) )
	{
		enableinfluencer(self.spawn_influencer, enabled);
	}
}

enable_initial_spawn_influencers( duration )
{
	// turn on the initial spawns		
	initial_spawn_influencer_ents = getentarray( self.target, "targetname" );
	
	// either both, or none
	if (initial_spawn_influencer_ents.size == 0)
		return;
		
	assert( initial_spawn_influencer_ents.size == 2 );

	ss = level.spawnsystem;
	
	mask1 = ss.iSPAWN_TEAMMASK_AXIS;
	mask2 = ss.iSPAWN_TEAMMASK_ALLIES;
	
	if (randomint(2) == 0)
	{	// switch them
		mask1 = ss.iSPAWN_TEAMMASK_ALLIES;
		mask2 = ss.iSPAWN_TEAMMASK_AXIS;
	}
	
	initial_spawn_influencers1 = addsphereinfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
							 initial_spawn_influencer_ents[0].origin, 
							 ss.koth_initial_spawns_influencer_radius,
							 ss.koth_initial_spawns_influencer_score,
							 mask1,
							 "koth_objective,r,s",
							 maps\mp\gametypes\_spawning::get_score_curve_index(ss.koth_initial_spawns_influencer_score_curve) );

	initial_spawn_influencers2 = addsphereinfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
							 initial_spawn_influencer_ents[0].origin, 
							 ss.koth_initial_spawns_influencer_radius,
							 ss.koth_initial_spawns_influencer_score,
							 mask1,
							 "koth_objective,r,s",
							 maps\mp\gametypes\_spawning::get_score_curve_index(ss.koth_initial_spawns_influencer_score_curve) );

	wait duration;
	
	removeinfluencer( initial_spawn_influencers1 );
	removeinfluencer( initial_spawn_influencers2 );

}

koth_gamemodeSpawnDvars(reset_dvars)
{
	ss = level.spawnsystem;

	// koth (hq): influencer placed around the radio
	ss.koth_objective_influencer_score =	set_dvar_float_if_unset("scr_spawn_koth_objective_influencer_score", "-400", reset_dvars);
	ss.koth_objective_influencer_score_curve =	set_dvar_if_unset("scr_spawn_koth_objective_influencer_score_curve", "constant", reset_dvars);
	ss.koth_objective_influencer_radius =	set_dvar_float_if_unset("scr_spawn_koth_objective_influencer_radius", "" + 20.0*get_player_height(), reset_dvars);

	// koth (hq): initial spawns influencer to help group starting players at predefined locations
	ss.koth_initial_spawns_influencer_score =	set_dvar_float_if_unset("scr_spawn_koth_initial_spawns_influencer_score", "200", reset_dvars);
	ss.koth_initial_spawns_influencer_score_curve =	set_dvar_if_unset("scr_spawn_koth_initial_spawns_influencer_score_curve", "linear", reset_dvars);
	ss.koth_initial_spawns_influencer_radius =	set_dvar_float_if_unset("scr_spawn_koth_initial_spawns_influencer_radius", "" + 10.0*get_player_height(), reset_dvars);
	
}
