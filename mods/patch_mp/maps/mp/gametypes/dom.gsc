#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
/*
	Domination
	Objective: 	Capture all the flags by touching them
	Map ends:	When one team captures all the flags, or time limit is reached
	Respawning:	No wait / Near teammates

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_tdm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of owned flags, teammates and 
			enemies at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.
			Optionally, give a spawnpoint a script_linkto to specify which flag it "belongs" to (see Flag Descriptors).

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

		Flags:
			classname       trigger_radius
			targetname      flag_primary or flag_secondary
			Flags that need to be captured to win. Primary flags take time to capture; secondary flags are instant.
		
		Flag Descriptors:
			classname       script_origin
			targetname      flag_descriptor
			Place one flag descriptor close to each flag. Use the script_linkname and script_linkto properties to say which flags
			it can be considered "adjacent" to in the level. For instance, if players have a primary path from flag1 to flag2, and 
			from flag2 to flag3, flag2 would have a flag_descriptor with these properties:
			script_linkname flag2
			script_linkto flag1 flag3
			
			Set scr_domdebug to 1 to see flag connections and what spawnpoints are considered connected to each flag.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "marines";
			game["axis"] = "nva";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.

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
*/

/*QUAKED mp_dom_spawn (0.5 0.5 1.0) (-16 -16 0) (16 16 72)
Players spawn near their flags at one of these positions.*/

/*QUAKED mp_dom_spawn_flag_a (0.5 0.5 1.0) (-16 -16 0) (16 16 72)
Players spawn near their flags at one of these positions.*/

/*QUAKED mp_dom_spawn_flag_b (0.5 0.5 1.0) (-16 -16 0) (16 16 72)
Players spawn near their flags at one of these positions.*/

/*QUAKED mp_dom_spawn_flag_c (0.5 0.5 1.0) (-16 -16 0) (16 16 72)
Players spawn near their flags at one of these positions.*/

/*QUAKED mp_dom_spawn_axis_start (1.0 0.0 1.0) (-16 -16 0) (16 16 72)
Axis players spawn away from enemies and near their team at one of these positions at the start of a round.*/

/*QUAKED mp_dom_spawn_allies_start (0.0 1.0 1.0) (-16 -16 0) (16 16 72)
Allied players spawn away from enemies and near their team at one of these positions at the start of a round.*/

main()
{
	if(GetDvar( #"mapname") == "mp_background")
		return;

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	maps\mp\gametypes\_globallogic_utils::registerTimeLimitDvar( "dom", 30, 0, 1440 );
	maps\mp\gametypes\_globallogic_utils::registerScoreLimitDvar( "dom", 200, 0, 1000 );
	maps\mp\gametypes\_globallogic_utils::registerRoundLimitDvar( "dom", 1, 0, 10 );
	maps\mp\gametypes\_globallogic_utils::registerRoundWinLimitDvar( "dom", 0, 0, 10 );
	maps\mp\gametypes\_globallogic_utils::registerNumLivesDvar( "dom", 0, 0, 10 );

	maps\mp\gametypes\_weapons::registerGrenadeLauncherDudDvar( level.gameType, 10, 0, 1440 );
	maps\mp\gametypes\_weapons::registerThrownGrenadeDudDvar( level.gameType, 0, 0, 1440 );
	maps\mp\gametypes\_weapons::registerKillstreakDelay( level.gameType, 0, 0, 1440 );

	maps\mp\gametypes\_globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );
	
	level.scoreRoundBased = true;
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onSpawnPlayerUnified = ::onSpawnPlayerUnified;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onEndGame= ::onEndGame;
	level.gamemodeSpawnDvars = ::dom_gamemodeSpawnDvars;
	level.onRoundEndGame = ::onRoundEndGame;

	game["dialog"]["gametype"] = "dom_start";
	game["dialog"]["gametype_hardcore"] = "hcdom_start";
	game["dialog"]["offense_obj"] = "cap_start";
	game["dialog"]["defense_obj"] = "cap_start";
	level.lastDialogTime = 0;
		
	// Sets the scoreboard columns and determines with data is sent across the network
	setscoreboardcolumns( "kills", "deaths" , "captures", "defends"); 

	if ( !isOneRound() && isScoreRoundBased() )
	{
		maps\mp\gametypes\_globallogic_score::resetTeamScores();
	}
}


onPrecacheGameType()
{
	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "compass_waypoint_captureneutral_a" );
	precacheShader( "compass_waypoint_capture_a" );
	precacheShader( "compass_waypoint_defend_a" );
	precacheShader( "compass_waypoint_captureneutral_b" );
	precacheShader( "compass_waypoint_capture_b" );
	precacheShader( "compass_waypoint_defend_b" );
	precacheShader( "compass_waypoint_captureneutral_c" );
	precacheShader( "compass_waypoint_capture_c" );
	precacheShader( "compass_waypoint_defend_c" );
	precacheShader( "compass_waypoint_captureneutral_d" );
	precacheShader( "compass_waypoint_capture_d" );
	precacheShader( "compass_waypoint_defend_d" );
	precacheShader( "compass_waypoint_captureneutral_e" );
	precacheShader( "compass_waypoint_capture_e" );
	precacheShader( "compass_waypoint_defend_e" );

	precacheShader( "waypoint_captureneutral" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	precacheShader( "waypoint_captureneutral_a" );
	precacheShader( "waypoint_capture_a" );
	precacheShader( "waypoint_defend_a" );
	precacheShader( "waypoint_captureneutral_b" );
	precacheShader( "waypoint_capture_b" );
	precacheShader( "waypoint_defend_b" );
	precacheShader( "waypoint_captureneutral_c" );
	precacheShader( "waypoint_capture_c" );
	precacheShader( "waypoint_defend_c" );
	precacheShader( "waypoint_captureneutral_d" );
	precacheShader( "waypoint_capture_d" );
	precacheShader( "waypoint_defend_d" );
	precacheShader( "waypoint_captureneutral_e" );
	precacheShader( "waypoint_capture_e" );
	precacheShader( "waypoint_defend_e" );
	
	/*flagBaseFX = [];
	
	flagBaseFX["marines"] =  "misc/fx_ui_flagbase_gold_t5";
	flagBaseFX["nva"] = "misc/fx_ui_flagbase_red";
	flagBaseFX["tropas"] = "misc/fx_ui_flagbase_red";
	flagBaseFX["specops"] = "misc/fx_ui_flagbase_gold";
	flagBaseFX["rebels"] = "misc/fx_ui_flagbase_gold";
	flagBaseFX["russian"] = "misc/fx_ui_flagbase_orange";
	*/
}


onStartGameType()
{	
	maps\mp\gametypes\_globallogic_ui::setObjectiveText( "allies", &"OBJECTIVES_DOM" );
	maps\mp\gametypes\_globallogic_ui::setObjectiveText( "axis", &"OBJECTIVES_DOM" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_DOM" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_DOM" );
	}
	else
	{
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "allies", &"OBJECTIVES_DOM_SCORE" );
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText( "axis", &"OBJECTIVES_DOM_SCORE" );
	}
	maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( "allies", &"OBJECTIVES_DOM_HINT" );
	maps\mp\gametypes\_globallogic_ui::setObjectiveHintText( "axis", &"OBJECTIVES_DOM_HINT" );
	
	level.flagBaseFXid = [];
	level.flagBaseFXid[ "allies" ] = loadfx( "misc/fx_ui_flagbase_gold_t5" );
	level.flagBaseFXid[ "axis"   ] = loadfx( "misc/fx_ui_flagbase_gold_t5" );

	setClientNameMode("auto_change");

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_axis_start" );
	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	spawnpoint = maps\mp\gametypes\_spawnlogic::getRandomIntermissionPoint();
	setDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );
	
	level.spawn_all = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn" );
	level.spawn_axis_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_axis_start" );
	level.spawn_allies_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_allies_start" );
	
	flagSpawns = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_flag_a" );
	//assert( flagSpawns.size > 0 );
	
	level.startPos["allies"] = level.spawn_allies_start[0].origin;
	level.startPos["axis"] = level.spawn_axis_start[0].origin;
	
	allowed[0] = "dom";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// now that the game objects have been deleted place the influencers
	maps\mp\gametypes\_spawning::create_map_placed_influencers();

	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_75", 40 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_50", 30 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_25", 20 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 10 );

	maps\mp\gametypes\_rank::registerScoreInfo( "capture", 150 );

	maps\mp\gametypes\_rank::registerScoreInfo( "defend", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "defend_assist", 10 );

	maps\mp\gametypes\_rank::registerScoreInfo( "assault", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assault_assist", 10 );
		
	updateGametypeDvars();
	thread domFlags();
	thread updateDomScores();
	level change_dom_spawns();
}


onSpawnPlayerUnified()
{
	maps\mp\gametypes\_spawning::onSpawnPlayer_Unified();
}

onSpawnPlayer()
{
	spawnpoint = undefined;
	
	if ( !level.useStartSpawns )
	{
		flagsOwned = 0;
		enemyFlagsOwned = 0;
		myTeam = self.pers["team"];
		enemyTeam = getOtherTeam( myTeam );
		for ( i = 0; i < level.flags.size; i++ )
		{
			team = level.flags[i] getFlagTeam();
			if ( team == myTeam )
				flagsOwned++;
			else if ( team == enemyTeam )
				enemyFlagsOwned++;
		}
		
		if ( flagsOwned == level.flags.size )
		{
			// own all flags! pretend we don't own the last one we got, so enemies can spawn there
			enemyBestSpawnFlag = level.bestSpawnFlag[ getOtherTeam( self.pers["team"] ) ];
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, getSpawnsBoundingFlag( enemyBestSpawnFlag ) );
		}
		else if ( flagsOwned > 0 )
		{
			// spawn near any flag we own that's nearish something we can capture
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, getBoundaryFlagSpawns( myTeam ) );
		}
		else
		{
			// own no flags!
			bestFlag = undefined;
			if ( enemyFlagsOwned > 0 && enemyFlagsOwned < level.flags.size )
			{
				// there should be an unowned one to use
				bestFlag = getUnownedFlagNearestStart( myTeam );
			}
			if ( !isdefined( bestFlag ) )
			{
				// pretend we still own the last one we lost
				bestFlag = level.bestSpawnFlag[ self.pers["team"] ];
			}
			level.bestSpawnFlag[ self.pers["team"] ] = bestFlag;
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, bestFlag.nearbyspawns );
		}
	}
	
	if ( !isdefined( spawnpoint ) )
	{
		if (self.pers["team"] == "axis")
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_axis_start);
		else
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_allies_start);
	}
	
	//spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all );
	
	assert( isDefined(spawnpoint) );
	
	self spawn(spawnpoint.origin, spawnpoint.angles, "dom");
}

onEndGame( winningTeam )
{
	for ( i = 0; i < level.domFlags.size; i++ )
	{
		level.domFlags[i] maps\mp\gametypes\_gameobjects::allowUse( "none" );
	}
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

updateGametypeDvars()
{
	level.flagCaptureTime = dvarFloatValue( "flagcapturetime", 10, 0, 30 );
	level.flagCaptureLPM = dvarFloatValue( "maxFlagCapturePerMinute", 3, 0, 10 );
	level.playerCaptureLPM = dvarFloatValue( "maxPlayerCapturePerMinute", 2, 0, 10 );
	level.playerCaptureMax = dvarFloatValue( "maxPlayerCapture", 1000, 0, 1000 );
	level.playerOffensiveMax = dvarFloatValue( "maxPlayerOffensive", 16, 0, 1000 );
	level.playerDefensiveMax = dvarFloatValue( "maxPlayerDefensive", 16, 0, 1000 );
}

domFlags()
{
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	game["flagmodels"] = [];
	game["flagmodels"]["neutral"] = "mp_flag_neutral";

	if ( game["allies"] == "marines" )
		game["flagmodels"]["allies"] = "mp_flag_allies_1";
	else if ( game["allies"] == "rebels" )
		game["flagmodels"]["allies"] = "mp_flag_allies_3";
	else
		game["flagmodels"]["allies"] = "mp_flag_allies_2";
	
	if ( game["axis"] == "russian" ) 
		game["flagmodels"]["axis"] = "mp_flag_axis_1";
	else if ( game["axis"] == "tropas" )
		game["flagmodels"]["axis"] = "mp_flag_axis_3";
	else
		game["flagmodels"]["axis"] = "mp_flag_axis_2";
	
	precacheModel( game["flagmodels"]["neutral"] );
	precacheModel( game["flagmodels"]["allies"] );
	precacheModel( game["flagmodels"]["axis"] );
	

	precacheString( &"MP_CAPTURING_FLAG" );
	precacheString( &"MP_LOSING_FLAG" );
	//precacheString( &"MP_LOSING_LAST_FLAG" );
	precacheString( &"MP_DOM_YOUR_FLAG_WAS_CAPTURED" );
	precacheString( &"MP_DOM_ENEMY_FLAG_CAPTURED" );
	precacheString( &"MP_DOM_NEUTRAL_FLAG_CAPTURED" );

	precacheString( &"MP_ENEMY_FLAG_CAPTURED_BY" );
	precacheString( &"MP_NEUTRAL_FLAG_CAPTURED_BY" );
	precacheString( &"MP_FRIENDLY_FLAG_CAPTURED_BY" );
	precacheString( &"MP_DOM_FLAG_A_CAPTURED_BY" );	
	precacheString( &"MP_DOM_FLAG_B_CAPTURED_BY" );	
	precacheString( &"MP_DOM_FLAG_C_CAPTURED_BY" );	
	precacheString( &"MP_DOM_FLAG_D_CAPTURED_BY" );	
	precacheString( &"MP_DOM_FLAG_E_CAPTURED_BY" );	

	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		printLn( "^1Not enough domination flags found in level!" );
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}
	
	level.flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[level.flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[level.flags.size] = secondaryFlags[index];
	
	level.domFlags = [];
	for ( index = 0; index < level.flags.size; index++ )
	{
		trigger = level.flags[index];
		if ( isDefined( trigger.target ) )
		{
			visuals[0] = getEnt( trigger.target, "targetname" );
		}
		else
		{
			visuals[0] = spawn( "script_model", trigger.origin );
			visuals[0].angles = trigger.angles;
		}

		visuals[0] setModel( game["flagmodels"]["neutral"] );
			
		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( level.flagCaptureTime );
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
		label = domFlag maps\mp\gametypes\_gameobjects::getLabel();	
		domFlag.label = label;
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_captureneutral" + label );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_captureneutral" + label );
		domFlag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		domFlag.onUse = ::onUse;
		domFlag.onBeginUse = ::onBeginUse;
		domFlag.onUseUpdate = ::onUseUpdate;
		domFlag.onEndUse = ::onEndUse;
		
		
		traceStart = visuals[0].origin + (0,0,32);
		traceEnd = visuals[0].origin + (0,0,-32);
		trace = bulletTrace( traceStart, traceEnd, false, undefined );
	
		upangles = vectorToAngles( trace["normal"] );
		domFlag.baseeffectforward = anglesToForward( upangles );
		domFlag.baseeffectright = anglesToRight( upangles );
		
		domFlag.baseeffectpos = trace["position"];
		
//		makeDvarServerInfo( "scr_obj" + label, "neutral" );
//		makeDvarServerInfo( "scr_obj" + label + "_flash", 0 );
//		setDvar( "scr_obj" + label, "neutral" );
//		setDvar( "scr_obj" + label + "_flash", 0 );

		// legacy spawn code support
		level.flags[index].useObj = domFlag;
		level.flags[index].adjflags = [];
		level.flags[index].nearbyspawns = [];
		
		domFlag.levelFlag = level.flags[index];
		
		level.domFlags[level.domFlags.size] = domFlag;
	}
	
	// level.bestSpawnFlag is used as a last resort when the enemy holds all flags.
	level.bestSpawnFlag = [];
	level.bestSpawnFlag[ "allies" ] = getUnownedFlagNearestStart( "allies", undefined );
	level.bestSpawnFlag[ "axis" ] = getUnownedFlagNearestStart( "axis", level.bestSpawnFlag[ "allies" ] );
	
	for ( index = 0; index < level.domFlags.size; index++ )
	{
		level.domFlags[index] createFlagSpawnInfluencers();
	}
	
	flagSetup();
	
//	setDvar( level.scoreLimitDvar, level.domFlags.size );

	/#
	thread domDebug();
	#/
}

getUnownedFlagNearestStart( team, excludeFlag )
{
	best = undefined;
	bestdistsq = undefined;
	for ( i = 0; i < level.flags.size; i++ )
	{
		flag = level.flags[i];
		
		if ( flag getFlagTeam() != "neutral" )
			continue;
		
		distsq = distanceSquared( flag.origin, level.startPos[team] );
		if ( (!isDefined( excludeFlag ) || flag != excludeFlag) && (!isdefined( best ) || distsq < bestdistsq) )
		{
			bestdistsq = distsq;
			best = flag;
		}
	}
	return best;
}

/#
domDebug()
{
	while(1)
	{
		if (GetDvar( #"scr_domdebug") != "1") {
			wait 2;
			continue;
		}
		
		while(1)
		{
			if (GetDvar( #"scr_domdebug") != "1")
				break;
			// show flag connections and each flag's spawnpoints
			for (i = 0; i < level.flags.size; i++) {
				for (j = 0; j < level.flags[i].adjflags.size; j++) {
					line(level.flags[i].origin, level.flags[i].adjflags[j].origin, (1,1,1));
				}
				
				for (j = 0; j < level.flags[i].nearbyspawns.size; j++) {
					line(level.flags[i].origin, level.flags[i].nearbyspawns[j].origin, (.2,.2,.6));
				}
				
				if ( level.flags[i] == level.bestSpawnFlag["allies"] )
					print3d( level.flags[i].origin, "allies best spawn flag" );
				if ( level.flags[i] == level.bestSpawnFlag["axis"] )
					print3d( level.flags[i].origin, "axis best spawn flag" );
			}
			wait .05;
		}
	}
}
#/

onBeginUse( player )
{
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 1 );	
	self.didStatusNotify = false;
	if ( ownerTeam == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";

	if ( ownerTeam == "neutral" )
	{
		
		if( getTime() - level.lastDialogTime > 5000 )
		{
			otherTeam = getOtherTeam( player.pers["team"] );
			statusDialog( "securing"+self.label, player.pers["team"] );
			//statusDialog( "losing"+self.label, otherTeam );
			level.lastDialogTime = getTime();
		}
		self.objPoints[player.pers["team"]] thread maps\mp\gametypes\_objpoints::startFlashing();
		return;
	}
		
	

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::startFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::startFlashing();
}


onUseUpdate( team, progress, change )
{
	if ( progress > 0.05 && change && !self.didStatusNotify )
	{
		ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
		if ( ownerTeam == "neutral" )
		{
			
			if( getTime() - level.lastDialogTime > 10000 )
			{
				otherTeam = getOtherTeam( team );
				statusDialog( "securing"+self.label, team );
				statusDialog( "losing"+self.label, otherTeam );
				level.lastDialogTime = getTime();
			}
		}
		else
		{
			if( getTime() - level.lastDialogTime > 10000 )
			{
				statusDialog( "losing"+self.label, ownerTeam );
				statusDialog( "securing"+self.label, team );
				level.lastDialogTime = getTime();
			}
		}

		self.didStatusNotify = true;
	}
}


statusDialog( dialog, team )
{
	time = getTime();
	if ( getTime() < level.lastStatus[team] + 6000 )
		return;
		
	thread delayedLeaderDialog( dialog, team );
	level.lastStatus[team] = getTime();	
}


onEndUse( team, player, success )
{
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 0 );

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
}


resetFlagBaseEffect()
{
	// once these get setup we never change them
	if ( isdefined( self.baseeffect ) )
		return;
	
	team = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	
	if ( team != "axis" && team != "allies" )
		return;
	
	fxid = level.flagBaseFXid[ team ];

	self.baseeffect = spawnFx( fxid, self.baseeffectpos, self.baseeffectforward, self.baseeffectright );
	triggerFx( self.baseeffect );
}

onUse( player )
{
	team = player.pers["team"];
	oldTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	label = self maps\mp\gametypes\_gameobjects::getLabel();
	
	player logString( "flag captured: " + self.label );
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
	self.visuals[0] setModel( game["flagmodels"][team] );
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel(), team );	
	
	self resetFlagBaseEffect();
	
	level.useStartSpawns = false;
	
	assert( team != "neutral" );

	string = &"";
	switch ( label ) 
	{
		case "_a":
		string = &"MP_DOM_FLAG_A_CAPTURED_BY";
		break;
		case "_b":
			string = &"MP_DOM_FLAG_B_CAPTURED_BY";
		break;
		case "_c":
			string = &"MP_DOM_FLAG_C_CAPTURED_BY";
		break;
		case "_d":
			string = &"MP_DOM_FLAG_D_CAPTURED_BY";
		break;
		case "_e":
			string = &"MP_DOM_FLAG_E_CAPTURED_BY";
		break;
		default:
		break;
	}
	assert ( string != &"" );
	
	// Copy touch list so there aren't any threading issues
	touchList = [];
	touchKeys = GetArrayKeys( self.touchList[team] );
	for ( i = 0 ; i < touchKeys.size ; i++ )
		touchList[touchKeys[i]] = self.touchList[team][touchKeys[i]];
	thread give_capture_credit( touchList, string );

	if ( oldTeam == "neutral" )
	{
		otherTeam = getOtherTeam( team );
		thread printAndSoundOnEveryone( team, otherTeam, &"", &"", "mp_war_objective_taken", undefined, "" );
		
		thread playSoundOnPlayers( "mus_dom_captured"+"_"+level.teamPostfix[team] );
		if ( getTeamFlagCount( team ) == level.flags.size )
		{

			statusDialog( "secure_all", team );
			statusDialog( "lost_all", otherTeam );
		}
		else
		{
			statusDialog( "secured"+self.label, team );
			statusDialog( "lost"+self.label, otherTeam );
		}
	}
	else
	{
		thread printAndSoundOnEveryone( team, oldTeam, &"", &"", "mp_war_objective_taken", "mp_war_objective_lost", "" );
		
//		thread delayedLeaderDialogBothTeams( "obj_lost", oldTeam, "obj_taken", team );

//		thread playSoundOnPlayers( "mus_dom_captured"+"_"+level.teamPostfix[team] );
		if ( getTeamFlagCount( team ) == level.flags.size )
		{

			statusDialog( "secure_all", team );
			statusDialog( "lost_all", oldTeam );
		}
		else
		{	
			statusDialog( "secured"+self.label, team );

			statusDialog( "lost"+self.label, oldTeam );
		}
		
		level.bestSpawnFlag[ oldTeam ] = self.levelFlag;
	}

	if ( dominated_challenge_check() ) 
	{
		maps\mp\_challenges::dominated( team );
	}
	self update_spawn_influencers( team );
	level change_dom_spawns();
}

give_capture_credit( touchList, string )
{
	wait .05;
	maps\mp\gametypes\_globallogic_utils::WaitTillSlowProcessAllowed();
	
	self updateCapsPerMinute();
	
	players = getArrayKeys( touchList );
	for ( i = 0; i < players.size; i++ )
	{
		player_from_touchlist = touchList[players[i]].player;
		player_from_touchlist updateCapsPerMinute();
		if ( !isScoreBoosting( player_from_touchlist, self ) )
		{
			maps\mp\gametypes\_globallogic_score::givePlayerScore( "capture", player_from_touchlist );
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

		level thread maps\mp\_popups::DisplayTeamMessageToAll( string, player_from_touchlist );
	}
}

delayedLeaderDialog( sound, team )
{
	wait .1;
	maps\mp\gametypes\_globallogic_utils::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic_audio::leaderDialog( sound, team );
}
delayedLeaderDialogBothTeams( sound1, team1, sound2, team2 )
{
	wait .1;
	maps\mp\gametypes\_globallogic_utils::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic_audio::leaderDialogBothTeams( sound1, team1, sound2, team2 );
}


updateDomScores()
{
	// disable score limit check to allow both axis and allies score to be processed
	level.endGameOnScoreLimit = false;
	//level.playingActionMusic = false;			

	while ( !level.gameEnded )
	{
		numOwnedFlags = 0;
		
		numFlags = getTeamFlagCount( "allies" );
		numOwnedFlags += numFlags;
		if ( numFlags )
			[[level._setTeamScore]]( "allies", [[level._getTeamScore]]( "allies" ) + numFlags );

		numFlags = getTeamFlagCount( "axis" );
		numOwnedFlags += numFlags;
		if ( numFlags )
			[[level._setTeamScore]]( "axis", [[level._getTeamScore]]( "axis" ) + numFlags );


		level.endGameOnScoreLimit = true;
		maps\mp\gametypes\_globallogic::checkScoreLimit();
		level.endGameOnScoreLimit = false;
		onScoreCloseMusic ();
		
		// end the game if people aren't playing
		timePassed = maps\mp\gametypes\_globallogic_utils::getTimePassed();
		if ( (((timePassed / 1000) > 120 && numOwnedFlags < 2) || ((timePassed / 1000) > 300 && numOwnedFlags < 3)) && ( level.onlinegame && !GetDvarInt( #"xblive_privatematch" ) ) )
		{
			thread maps\mp\gametypes\_globallogic::endGame( "tie", game["strings"]["time_limit_reached"] );
			return;
		}
		
		wait ( 5.0 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
}
onScoreCloseMusic ()
{
	axisScore = [[level._getTeamScore]]( "axis" );
	alliedScore = [[level._getTeamScore]]( "allies" );
	scoreLimit = level.scoreLimit;
	scoreThreshold = scoreLimit * .1;
	scoreDif = abs(axisScore - alliedScore);
	scoreThresholdStart = abs(scoreLimit - scoreThreshold);
	scoreLimitCheck = scoreLimit - 10;
	
	if( !IsDefined( level.playingActionMusic ) )
	    level.playingActionMusic = false;
	
	if (alliedScore > axisScore)
	{
		currentScore = alliedScore;
	}		
	else
	{
		currentScore = axisScore;
	}	
	if( getdvarint( #"debug_music" ) > 0 )
	{
			println ("Music System Domination - scoreDif " + scoreDif);
			println ("Music System Domination - axisScore " + axisScore);
			println ("Music System Domination - alliedScore " + alliedScore);
			println ("Music System Domination - scoreLimit " + scoreLimit);							
			println ("Music System Domination - currentScore " + currentScore);
			println ("Music System Domination - scoreThreshold " + scoreThreshold);								
			println ("Music System Domination - scoreDif " + scoreDif);
			println ("Music System Domination - scoreThresholdStart " + scoreThresholdStart);									
	}
	if ( scoreDif <= scoreThreshold && scoreThresholdStart <= currentScore && (level.playingActionMusic != true))
	{
		//play some action music
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "TIME_OUT", "both" );
		thread maps\mp\gametypes\_globallogic_audio::actionMusicSet();
	}	
/*	else if (scoreDif >= scoreThreshold && level.playingActionMusic && currentScore <= scoreLimitCheck )
	{ 
		//TODO : Decide if we want to stop music on large score spread CDC
		// if we are playing some action music and the score starts to be a blow out return to last state
		thread maps\mp\gametypes\_globallogic_audio::return_music_state_team( "both" );
		level.playingActionMusic = false;		
	}	
*/
	else
	{
		return;
	}	
}	
onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( self.touchTriggers.size && isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] )
	{
		triggerIds = getArrayKeys( self.touchTriggers );
		ownerTeam = self.touchTriggers[triggerIds[0]].useObj.ownerTeam;
		team = self.pers["team"];
		
		if ( team == ownerTeam )
		{
			if ( !IsDefined( attacker.dom_offends ) )
				attacker.dom_offends = 0;
				
			attacker.dom_offends++;
			
			if ( level.playerOffensiveMax >= attacker.dom_offends )
			{
				attacker thread [[level.onXPEvent]]( "assault" );
				if ( !isdefined( sWeapon ) || !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) )
				{
					attacker maps\mp\_medals::offense( sWeapon );
					attacker maps\mp\gametypes\_persistence::statAddWithGameType( "OFFENDS", 1 );
				}
	
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "assault", attacker );
			}
		}
		else
		{
			if ( !IsDefined( attacker.dom_defends ) )
				attacker.dom_defends = 0;

			attacker.dom_defends++;
			
			if ( level.playerDefensiveMax >= attacker.dom_defends )
			{
				attacker thread [[level.onXPEvent]]( "defend" );
				if ( !isdefined( sWeapon ) || !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) )
				{
					attacker maps\mp\_medals::defense( sWeapon );
					attacker maps\mp\gametypes\_persistence::statAddWithGameType( "DEFENDS", 1 );
				}
	
				if( isdefined(attacker.pers["defends"]) )
				{
					attacker.pers["defends"]++;
					attacker.defends = attacker.pers["defends"];
				}
	
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "defend", attacker );
			}
		}
	}
}



getTeamFlagCount( team )
{
	score = 0;
	for (i = 0; i < level.flags.size; i++) 
	{
		if ( level.domFlags[i] maps\mp\gametypes\_gameobjects::getOwnerTeam() == team )
			score++;
	}	
	return score;
}

getFlagTeam()
{
	return self.useObj maps\mp\gametypes\_gameobjects::getOwnerTeam();
}

getBoundaryFlags()
{
	// get all flags which are adjacent to flags that aren't owned by the same team
	bflags = [];
	for (i = 0; i < level.flags.size; i++)
	{
		for (j = 0; j < level.flags[i].adjflags.size; j++)
		{
			if (level.flags[i].useObj maps\mp\gametypes\_gameobjects::getOwnerTeam() != level.flags[i].adjflags[j].useObj maps\mp\gametypes\_gameobjects::getOwnerTeam() )
			{
				bflags[bflags.size] = level.flags[i];
				break;
			}
		}
	}
	
	return bflags;
}

getBoundaryFlagSpawns(team)
{
	spawns = [];
	
	bflags = getBoundaryFlags();
	for (i = 0; i < bflags.size; i++)
	{
		if (isdefined(team) && bflags[i] getFlagTeam() != team)
			continue;
		
		for (j = 0; j < bflags[i].nearbyspawns.size; j++)
			spawns[spawns.size] = bflags[i].nearbyspawns[j];
	}
	
	return spawns;
}

getSpawnsBoundingFlag( avoidflag )
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		flag = level.flags[i];
		if ( flag == avoidflag )
			continue;
		
		isbounding = false;
		for (j = 0; j < flag.adjflags.size; j++)
		{
			if ( flag.adjflags[j] == avoidflag )
			{
				isbounding = true;
				break;
			}
		}
		
		if ( !isbounding )
			continue;
		
		for (j = 0; j < flag.nearbyspawns.size; j++)
			spawns[spawns.size] = flag.nearbyspawns[j];
	}
	
	return spawns;
}

// gets an array of all spawnpoints which are near flags that are
// owned by the given team, or that are adjacent to flags owned by the given team.
getOwnedAndBoundingFlagSpawns(team)
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		if ( level.flags[i] getFlagTeam() == team )
		{
			// add spawns near this flag
			for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
				spawns[spawns.size] = level.flags[i].nearbyspawns[s];
		}
		else
		{
			for (j = 0; j < level.flags[i].adjflags.size; j++)
			{
				if ( level.flags[i].adjflags[j] getFlagTeam() == team )
				{
					// add spawns near this flag
					for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
						spawns[spawns.size] = level.flags[i].nearbyspawns[s];
					break;
				}
			}
		}
	}
	
	return spawns;
}

// gets an array of all spawnpoints which are near flags that are
// owned by the given team
getOwnedFlagSpawns(team)
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		if ( level.flags[i] getFlagTeam() == team )
		{
			// add spawns near this flag
			for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
				spawns[spawns.size] = level.flags[i].nearbyspawns[s];
		}
	}
	
	return spawns;
}

flagSetup()
{
	maperrors = [];
	descriptorsByLinkname = [];

	// (find each flag_descriptor object)
	descriptors = getentarray("flag_descriptor", "targetname");
	
	flags = level.flags;
	
	for (i = 0; i < level.domFlags.size; i++)
	{
		closestdist = undefined;
		closestdesc = undefined;
		for (j = 0; j < descriptors.size; j++)
		{
			dist = distance(flags[i].origin, descriptors[j].origin);
			if (!isdefined(closestdist) || dist < closestdist) {
				closestdist = dist;
				closestdesc = descriptors[j];
			}
		}
		
		if (!isdefined(closestdesc)) {
			maperrors[maperrors.size] = "there is no flag_descriptor in the map! see explanation in dom.gsc";
			break;
		}
		if (isdefined(closestdesc.flag)) {
			maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + closestdesc.script_linkname + "\" is nearby more than one flag; is there a unique descriptor near each flag?";
			continue;
		}
		flags[i].descriptor = closestdesc;
		closestdesc.flag = flags[i];
		descriptorsByLinkname[closestdesc.script_linkname] = closestdesc;
	}
	
	if (maperrors.size == 0)
	{
		// find adjacent flags
		for (i = 0; i < flags.size; i++)
		{
			if (isdefined(flags[i].descriptor.script_linkto))
				adjdescs = strtok(flags[i].descriptor.script_linkto, " ");
			else
				adjdescs = [];
			for (j = 0; j < adjdescs.size; j++)
			{
				otherdesc = descriptorsByLinkname[adjdescs[j]];
				if (!isdefined(otherdesc) || otherdesc.targetname != "flag_descriptor") {
					maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + flags[i].descriptor.script_linkname + "\" linked to \"" + adjdescs[j] + "\" which does not exist as a script_linkname of any other entity with a targetname of flag_descriptor (or, if it does, that flag_descriptor has not been assigned to a flag)";
					continue;
				}
				adjflag = otherdesc.flag;
				if (adjflag == flags[i]) {
					maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + flags[i].descriptor.script_linkname + "\" linked to itself";
					continue;
				}
				flags[i].adjflags[flags[i].adjflags.size] = adjflag;
			}
		}
	}
	
	// assign each spawnpoint to nearest flag
	spawnpoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn" );
	for (i = 0; i < spawnpoints.size; i++)
	{
		if (isdefined(spawnpoints[i].script_linkto)) {
			desc = descriptorsByLinkname[spawnpoints[i].script_linkto];
			if (!isdefined(desc) || desc.targetname != "flag_descriptor") {
				maperrors[maperrors.size] = "Spawnpoint at " + spawnpoints[i].origin + "\" linked to \"" + spawnpoints[i].script_linkto + "\" which does not exist as a script_linkname of any entity with a targetname of flag_descriptor (or, if it does, that flag_descriptor has not been assigned to a flag)";
				continue;
			}
			nearestflag = desc.flag;
		}
		else {
			nearestflag = undefined;
			nearestdist = undefined;
			for (j = 0; j < flags.size; j++)
			{
				dist = distancesquared(flags[j].origin, spawnpoints[i].origin);
				if (!isdefined(nearestflag) || dist < nearestdist)
				{
					nearestflag = flags[j];
					nearestdist = dist;
				}
			}
		}
		nearestflag.nearbyspawns[nearestflag.nearbyspawns.size] = spawnpoints[i];
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
}

createFlagSpawnInfluencers()
{
	ss = level.spawnsystem;

	for (flag_index = 0; flag_index < level.flags.size; flag_index++)
	{
		if ( level.domFlags[flag_index] == self )
			break;
	}
	
	ABC = [];
	ABC[0] = "A";
	ABC[1] = "B";
	ABC[2] = "C";
	
	// domination: owned flag influencers
	self.owned_flag_influencer = addsphereinfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
							 self.trigger.origin, 
							 ss.dom_owned_flag_influencer_radius[flag_index],
							 ss.dom_owned_flag_influencer_score[flag_index],
							 0,
							 "dom_owned_flag_" + ABC[flag_index] + ",r,s",
							 maps\mp\gametypes\_spawning::get_score_curve_index(ss.dom_owned_flag_influencer_score_curve) );
	
	// domination: un-owned inner flag influencers
	self.neutral_flag_influencer = addsphereinfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
							 self.trigger.origin, 
							 ss.dom_unowned_flag_influencer_radius,
							 ss.dom_unowned_flag_influencer_score,
							 0,
							 "dom_unowned_flag,r,s",
							 maps\mp\gametypes\_spawning::get_score_curve_index(ss.dom_owned_flag_influencer_score_curve) );
		
	// domination: enemy flag influencers
	self.enemy_flag_influencer = addsphereinfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
							 self.trigger.origin, 
							 ss.dom_enemy_flag_influencer_radius[flag_index],
							 ss.dom_enemy_flag_influencer_score[flag_index],
							 0,
							 "dom_enemy_flag_" + ABC[flag_index] + ",r,s",
							 maps\mp\gametypes\_spawning::get_score_curve_index(ss.dom_enemy_flag_influencer_score_curve) );
	
	
	// default it to neutral
	self update_spawn_influencers("neutral");
}

update_spawn_influencers( team )
{
	assert(isdefined(self.neutral_flag_influencer));
	assert(isdefined(self.owned_flag_influencer));
	assert(isdefined(self.enemy_flag_influencer));
	
	if ( team == "neutral" )
	{
		enableinfluencer(self.neutral_flag_influencer, true);
		enableinfluencer(self.owned_flag_influencer, false);
		enableinfluencer(self.enemy_flag_influencer, false);
	}
	else
	{
		enableinfluencer(self.neutral_flag_influencer, false);
		enableinfluencer(self.owned_flag_influencer, true);
		enableinfluencer(self.enemy_flag_influencer, true);
	}
	
	if ( team == "allies" )
	{
		setinfluencerteammask(self.owned_flag_influencer, level.spawnsystem.iSPAWN_TEAMMASK_ALLIES );
		setinfluencerteammask(self.enemy_flag_influencer, level.spawnsystem.iSPAWN_TEAMMASK_AXIS );
	}
	else
	{
		setinfluencerteammask(self.owned_flag_influencer, level.spawnsystem.iSPAWN_TEAMMASK_AXIS );
		setinfluencerteammask(self.enemy_flag_influencer, level.spawnsystem.iSPAWN_TEAMMASK_ALLIES );
	}
	
}

dom_gamemodeSpawnDvars(reset_dvars)
{
	ss = level.spawnsystem;

	// domination: owned flag influencers
	ss.dom_owned_flag_influencer_score = [];
	ss.dom_owned_flag_influencer_radius = [];
	
	ss.dom_owned_flag_influencer_score[0] = set_dvar_float_if_unset("scr_spawn_dom_owned_flag_A_influencer_score", "10", reset_dvars);
	ss.dom_owned_flag_influencer_radius[0] = set_dvar_float_if_unset("scr_spawn_dom_owned_flag_A_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
	ss.dom_owned_flag_influencer_score[1] = set_dvar_float_if_unset("scr_spawn_dom_owned_flag_B_influencer_score", "10", reset_dvars);
	ss.dom_owned_flag_influencer_radius[1] = set_dvar_float_if_unset("scr_spawn_dom_owned_flag_B_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
	ss.dom_owned_flag_influencer_score[2] = set_dvar_float_if_unset("scr_spawn_dom_owned_flag_C_influencer_score", "10", reset_dvars);
	ss.dom_owned_flag_influencer_radius[2] = set_dvar_float_if_unset("scr_spawn_dom_owned_flag_C_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
	
	ss.dom_owned_flag_influencer_score_curve = set_dvar_if_unset("scr_spawn_dom_owned_flag_influencer_score_curve", "constant", reset_dvars);
	
	// domination: enemy flag influencers
	ss.dom_enemy_flag_influencer_score = [];
	ss.dom_enemy_flag_influencer_radius = [];
	
	ss.dom_enemy_flag_influencer_score[0] = set_dvar_float_if_unset("scr_spawn_dom_enemy_flag_A_influencer_score", "-10", reset_dvars);
	ss.dom_enemy_flag_influencer_radius[0] = set_dvar_float_if_unset("scr_spawn_dom_enemy_flag_A_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
	ss.dom_enemy_flag_influencer_score[1] = set_dvar_float_if_unset("scr_spawn_dom_enemy_flag_B_influencer_score", "-10", reset_dvars);
	ss.dom_enemy_flag_influencer_radius[1] = set_dvar_float_if_unset("scr_spawn_dom_enemy_flag_B_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
	ss.dom_enemy_flag_influencer_score[2] = set_dvar_float_if_unset("scr_spawn_dom_enemy_flag_C_influencer_score", "-10", reset_dvars);
	ss.dom_enemy_flag_influencer_radius[2] = set_dvar_float_if_unset("scr_spawn_dom_enemy_flag_C_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);

	ss.dom_enemy_flag_influencer_score_curve = set_dvar_if_unset("scr_spawn_dom_enemy_flag_influencer_score_curve", "constant", reset_dvars);
	
	// domination: un-owned inner flag influencers
	ss.dom_unowned_flag_influencer_score =	set_dvar_float_if_unset("scr_spawn_dom_unowned_flag_influencer_score", "-500", reset_dvars);
	ss.dom_unowned_flag_influencer_score_curve =	set_dvar_if_unset("scr_spawn_dom_unowned_flag_influencer_score_curve", "constant", reset_dvars);
	ss.dom_unowned_flag_influencer_radius =	set_dvar_float_if_unset("scr_spawn_dom_unowned_flag_influencer_radius", "" + 15.0*get_player_height(), reset_dvars);
}

//Changes what spawns are available to a team based on what Domination point they own
change_dom_spawns()
{

	maps\mp\gametypes\_spawnlogic::clearSpawnPoints();	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dom_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dom_spawn" );
	
	//If one team owns all flags, we want to allow both teams to spawn anywhere
	flag_number = level.flags.size;
	if( dominated_check() )
	{
		for ( i = 0 ; i < flag_number ; i++ )
		{
			label = level.flags[i].useobj maps\mp\gametypes\_gameobjects::getLabel();
			flagSpawnName = "mp_dom_spawn_flag" + label;
			maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", flagSpawnName );
			maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", flagSpawnName );
		}
	}
	else
	{
		for ( i = 0; i < flag_number; i++ )
		{
			//'getlabel' gives us the appropriate "_a" or "_b"
			label = level.flags[i].useobj maps\mp\gametypes\_gameobjects::getLabel();
			flagSpawnName = "mp_dom_spawn_flag" + label;
			flag_team = level.flags[i] getFlagTeam();

			if ( flag_team != "allies" )
			{
				maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", flagSpawnName );
			}
			
			if ( flag_team != "axis" )
			{
				maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", flagSpawnName );
			}
		}
	}

	maps\mp\gametypes\_spawning::updateAllSpawnPoints();

}

dominated_challenge_check()
{
	num_flags = level.flags.size;
	allied_flags = 0;
	axis_flags = 0;

	for ( i = 0 ; i < num_flags ; i++ )
	{
		flag_team = level.flags[i] getFlagTeam();

		if ( flag_team == "allies" )
		{
			allied_flags++;
		}
		else if ( flag_team == "axis" )
		{
			axis_flags++;
		}
		else
		{
			return false;
		}

		if ( ( allied_flags > 0 ) && ( axis_flags > 0 ) )
			return false;
	}

	return true;
}
//This function checks to see if one team owns all three flags
dominated_check()
{
	num_flags = level.flags.size;
	allied_flags = 0;
	axis_flags = 0;

	for ( i = 0 ; i < num_flags ; i++ )
	{
		flag_team = level.flags[i] getFlagTeam();

		if ( flag_team == "allies" )
		{
			allied_flags++;
		}
		else if ( flag_team == "axis" )
		{
			axis_flags++;
		}
		
		if ( ( allied_flags > 0 ) && ( axis_flags > 0 ) )
			return false;
	}

	return true;
}

updateCapsPerMinute()
{
	if ( !isDefined( self.capsPerMinute ) )
	{
		self.numCaps = 0;
		self.capsPerMinute = 0;
	}
	
	self.numCaps++;
	
	minutesPassed = maps\mp\gametypes\_globallogic_utils::getTimePassed() / ( 60 * 1000 );
	
	// players use the actual time played
	if ( IsPlayer( self ) && IsDefined(self.timePlayed["total"]) )
		minutesPassed = self.timePlayed["total"] / 60;
		
	self.capsPerMinute = self.numCaps / minutesPassed;
	if ( self.capsPerMinute > self.numCaps )
		self.capsPerMinute = self.numCaps;
}

isScoreBoosting( player, flag )
{
	if ( player.capsPerMinute > level.playerCaptureLPM )
		return true;
			
	if ( flag.capsPerMinute > level.flagCaptureLPM )
	  return true;
	  
	if ( player.numCaps > level.playerCaptureMax )
		return true;
			
 return false;
}