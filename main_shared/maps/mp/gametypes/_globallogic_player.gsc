#include maps\mp\_utility;
#include common_scripts\utility;

freezePlayerForRoundEnd()
{
	self clearLowerMessage();
	
	self closeMenu();
	self closeInGameMenu();
	
	self freeze_player_controls( true );
	currentWeapon = self GetCurrentWeapon();
	if ( maps\mp\gametypes\_hardpoints::isKillstreakWeapon( currentWeapon ) && !maps\mp\gametypes\_killstreak_weapons::isHeldKillstreakWeapon( currentWeapon ) )
		self takeWeapon( currentWeapon );
//	self _disableWeapon();
}


Callback_PlayerConnect()
{
	thread notifyConnecting();

	self.statusicon = "hud_status_connecting";
	self waittill( "begin" );
	waittillframeend;
	self.statusicon = "";

	level notify( "connected", self );
	
//	self thread maps\mp\gametypes\_globallogic_utils::fakeLag();
	if ( level.console && self IsHost() )
		self thread maps\mp\gametypes\_globallogic::listenForGameEnd();

	// only print that we connected if we haven't connected in a previous round
	if( !level.splitscreen && !isdefined( self.pers["score"] ) )
	{
		iPrintLn(&"MP_CONNECTED", self);
	}

	if( !isdefined( self.pers["score"] ) )
	{
		self thread maps\mp\gametypes\_persistence::adjustRecentStats();
		self maps\mp\gametypes\_persistence::setAfterActionReportStat( "valid", 0 );
		if( level.console )
		{
			if ( GetDvarInt( #"xblive_wagermatch" ) == 1 && !( self IsHost() ) )
				self maps\mp\gametypes\_persistence::setAfterActionReportStat( "wagerMatchFailed", 1 );
			else
				self maps\mp\gametypes\_persistence::setAfterActionReportStat( "wagerMatchFailed", 0 );
		}
		else
		{
			/#
			PrintLn("level.wagermatch: " + level.wagermatch );
			#/
			if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
			{
				if ( !self is_bot() && !self isdemoclient() )
				{
					codPoints = self maps\mp\gametypes\_persistence::statGet( "CODPOINTS" );
					if( codPoints < level.wagerBet && !self IsHost() )
					{
						/#
						PrintLn("kick " + self.name + "; not enought codpoints: " + codPoints );
						#/
						kick( self getEntityNumber(), "PLATFORM_WAGER_DEADBEAT_TITLE" );
						return;
					}
				}

				// set this flag to notify player of possible refund in case the match does not end well
				// self maps\mp\gametypes\_persistence::setAfterActionReportStat( "wagerMatchFailed", 1 );
			}
			else
				self maps\mp\gametypes\_persistence::setAfterActionReportStat( "wagerMatchFailed", 0 );			
		}
	}		
	
	// track match and hosting stats once per match
	if ( !IsDefined( self.pers["matchesPlayedStatsTracked"] ) )
	{
		self maps\mp\gametypes\_persistence::statAdd( "MATCHES_PLAYED", 1, false );
		self.pers["MATCHES_PLAYED_COMPLETED_STREAK"] = self maps\mp\gametypes\_persistence::statGet( "MATCHES_PLAYED_COMPLETED_STREAK" ) + 1;
		self maps\mp\gametypes\_persistence::statSet( "MATCHES_PLAYED_COMPLETED_STREAK", 0, false );
		
		if ( !IsDefined( self.pers["matchesHostedStatsTracked"] ) && self IsLocalToHost() )
		{
			self maps\mp\gametypes\_persistence::statAdd( "MATCHES_HOSTED", 1, false );
			self.pers["MATCHES_HOSTED_COMPLETED_STREAK"] = self maps\mp\gametypes\_persistence::statGet( "MATCHES_HOSTED_COMPLETED_STREAK" ) + 1;
			self maps\mp\gametypes\_persistence::statSet( "MATCHES_HOSTED_COMPLETED_STREAK", 0, false );
			self.pers["matchesHostedStatsTracked"] = true;
		}
		
		self.pers["matchesPlayedStatsTracked"] = true;
		self thread maps\mp\gametypes\_persistence::uploadStatsSoon();
	}

	self maps\mp\_gamerep::gameRepPlayerConnected();

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("J;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
	bbPrint( "mpjoins: name %s client %s", self.name, lpselfnum );
	
	self setClientUIVisibilityFlag( "hud_visible", 1 );
	self setClientUIVisibilityFlag( "g_compassShowEnemies", GetDvarInt( #"scr_game_forceradar" ) );

	self setClientDvars( "player_sprintTime", GetDvar( #"scr_player_sprinttime" ),
						 "ui_radar_client", GetDvar( #"ui_radar_client" ),
						 "scr_numLives", level.numLives,
						 "ui_pregame", isPregame() );
						 
	self CameraActivate( false );

	makeDvarServerInfo( "cg_drawTalk", 1 );
	
	if ( level.hardcoreMode )
	{
		self setClientDvars( "cg_drawTalk", 3 );
	}

	if ( GetDvarInt( #"player_sprintUnlimited" ) )
	{
		self setClientDvar( "player_sprintUnlimited", 1 );
	}

/#
	if ( GetDvarInt( #"scr_hitloc_debug") )
	{
		for ( i = 0; i < 6; i++ )
		{
			self setClientDvar( "ui_hitloc_" + i, "" );
		}
		self.hitlocInited = true;
	}
#/
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "score" );
	if ( level.resetPlayerScoreEveryRound )
	{
		self.pers["score"] = 0;
	}
	self.score = self.pers["score"];

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "suicides" );
	self.suicides = self  maps\mp\gametypes\_globallogic_score::getPersStat( "suicides" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "headshots" );
	self.headshots = self  maps\mp\gametypes\_globallogic_score::getPersStat( "headshots" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "challenges" );
	self.challenges = self  maps\mp\gametypes\_globallogic_score::getPersStat( "challenges" );	

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "kills" );
	self.kills = self  maps\mp\gametypes\_globallogic_score::getPersStat( "kills" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "deaths" );
	self.deaths = self  maps\mp\gametypes\_globallogic_score::getPersStat( "deaths" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "assists" );
	self.assists = self  maps\mp\gametypes\_globallogic_score::getPersStat( "assists" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "defends", false );
	self.defends = self  maps\mp\gametypes\_globallogic_score::getPersStat( "defends" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "offends", false );
	self.offends = self  maps\mp\gametypes\_globallogic_score::getPersStat( "offends" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "plants", false );
	self.plants = self  maps\mp\gametypes\_globallogic_score::getPersStat( "plants" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "defuses", false );
	self.defuses = self  maps\mp\gametypes\_globallogic_score::getPersStat( "defuses" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "returns", false );
	self.returns = self  maps\mp\gametypes\_globallogic_score::getPersStat( "returns" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "captures", false );
	self.captures = self  maps\mp\gametypes\_globallogic_score::getPersStat( "captures" );

	self  maps\mp\gametypes\_globallogic_score::initPersStat( "destructions", false );
	self.destructions = self  maps\mp\gametypes\_globallogic_score::getPersStat( "destructions" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "backstabs" );
	self.backstabs = self  maps\mp\gametypes\_globallogic_score::getPersStat( "backstabs" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "longshots" );
	self.longshots = self  maps\mp\gametypes\_globallogic_score::getPersStat( "longshots" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "survived" );
	self.survived = self  maps\mp\gametypes\_globallogic_score::getPersStat( "survived" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "stabs" );
	self.stabs = self  maps\mp\gametypes\_globallogic_score::getPersStat( "stabs" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "tomahawks" );
	self.tomahawks = self  maps\mp\gametypes\_globallogic_score::getPersStat( "tomahawks" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "humiliated" );
	self.humiliated = self  maps\mp\gametypes\_globallogic_score::getPersStat( "humiliated" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "x2score" );
	self.x2score = self  maps\mp\gametypes\_globallogic_score::getPersStat( "x2score" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "sessionbans" );
	self.sessionbans = self  maps\mp\gametypes\_globallogic_score::getPersStat( "sessionbans" );
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "gametypeban" );
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "time_played_total" );
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "time_played_alive" );
	
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "teamkills", false );
	self  maps\mp\gametypes\_globallogic_score::initPersStat( "teamkills_nostats" );
	self.teamKillPunish = false;
	if ( level.minimumAllowedTeamKills >= 0 && self.pers["teamkills_nostats"] > level.minimumAllowedTeamKills )
		self thread reduceTeamKillsOverTime();
	
	if( GetDvar( #"r_reflectionProbeGenerate" ) == "1" )
		level waittill( "eternity" );

	
	self.killedPlayersCurrent = [];

	if( !isDefined( self.pers["best_kill_streak"] ) )
	{
		self.pers["killed_players"] = [];
		self.pers["killed_by"] = [];
		self.pers["nemesis_tracking"] = [];
		self.pers["artillery_kills"] = 0;
		self.pers["dog_kills"] = 0;
		self.pers["nemesis_name"] = "";
		self.pers["nemesis_rank"] = 0;
		self.pers["nemesis_rankIcon"] = 0;
		self.pers["nemesis_xp"] = 0;
		self.pers["nemesis_xuid"] = "";


		/*self.killstreakKills["artillery"] = 0;
		self.killstreakKills["dogs"] = 0;
		self.killstreaksUsed["radar"] = 0;
		self.killstreaksUsed["artillery"] = 0;
		self.killstreaksUsed["dogs"] = 0;*/
		self.pers["best_kill_streak"] = 0;
	}

// Adding Music tracking per player CDC
	if( !isDefined( self.pers["music"] ) )
	{
		self.pers["music"] = spawnstruct();
		self.pers["music"].spawn = false;
		self.pers["music"].inque = false;		
		self.pers["music"].currentState = "SILENT";
		self.pers["music"].previousState = "SILENT";
		self.pers["music"].nextstate = "UNDERSCORE";
		self.pers["music"].returnState = "UNDERSCORE";	
		
	}		
	self.leaderDialogQueue = [];
	self.leaderDialogActive = false;
	self.leaderDialogGroups = [];
	self.leaderDialogGroup = "";

	if ( !isdefined( self.pers["cur_kill_streak"] ) )
		self.pers["cur_kill_streak"] = 0;
	if ( !isdefined( self.pers["totalKillstreakCount"] ) )
		self.pers["totalKillstreakCount"] = 0;

	//Keep track of how many killstreaks have been earned in the current streak
	if ( !isdefined( self.pers["killstreaksEarnedThisKillstreak"] ) )
		self.pers["killstreaksEarnedThisKillstreak"] = 0;

	self.lastKillTime = 0;
	
	self.cur_death_streak = 0;
	self disabledeathstreak();
	self.death_streak = 0;
	self.kill_streak = 0;
	self.gametype_kill_streak = 0;
	
	if ( level.onlineGame )
	{
		self.death_streak = self getDStat( "HighestStats",  "death_streak" );
		self.kill_streak = self getDStat( "HighestStats", "kill_streak" );
		self.gametype_kill_streak = self maps\mp\gametypes\_persistence::statGetWithGameType( "kill_streak" );
	}


	self.lastGrenadeSuicideTime = -1;

	self.teamkillsThisRound = 0;
	
	if ( !isDefined( level.livesDoNotReset ) || !level.livesDoNotReset || !isDefined( self.pers["lives"] ) )
		self.pers["lives"] = level.numLives;
		
	// multi round FFA games in custom game mode should maintain team in-between rounds
	if ( !level.teamBased && !maps\mp\gametypes\_customClasses::isCustomGame() )
	{
		self.pers["team"] = undefined;
	}
	
	self.hasSpawned = false;
	self.waitingToSpawn = false;
	self.wantSafeSpawn = false;
	self.deathCount = 0;
	
	self.wasAliveAtMatchStart = false;
	
	self thread maps\mp\_flashgrenades::monitorFlash();
	
	level.players[level.players.size] = self;
	
	if( level.splitscreen )
		setdvar( "splitscreen_playerNum", level.players.size );
	// removed underscore for debug CDC
	//maps\mp\gametypes\_globallogic_audio::set_music_on_team( "UNDERSCORE", "both", true );;
	// When joining a game in progress, if the game is at the post game state (scoreboard) the connecting player should spawn into intermission
	if ( game["state"] == "postgame" )
	{
		self.pers["needteam"] = 1;
		self.pers["team"] = "spectator";
		self.team = "spectator";
	    self setClientUIVisibilityFlag( "hud_visible", 0 );
		
		self [[level.spawnIntermission]]();
		self closeMenu();
		self closeInGameMenu();
		return;
	}

	// don't count losses for CTF and S&D and War at each round.
	if ( !isDefined( self.pers["lossAlreadyReported"] ) )
	{
			maps\mp\gametypes\_globallogic_score::updateLossStats( self );
			self.pers["lossAlreadyReported"] = true;
	}
	// don't redo winstreak save to pers array for each round of round based games.
	if ( !isDefined( self.pers["winstreakAlreadyCleared"] ) )
	{
			// self  maps\mp\gametypes\_globallogic_score::backupAndClearWinStreaks();
			self.pers["winstreakAlreadyCleared"] = true;
	}
		
	if( self isdemoclient() )
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getRandomIntermissionPoint();
		setDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );
		self.pers["team"] = "";
		self [[level.spectator]]();
	 	return;
	}
	
	if( self istestclient() )
	{
		self.pers[ "isBot" ] = true;
	}
	
	if ( level.rankedMatch )
	{
		self maps\mp\gametypes\_persistence::setAfterActionReportStat( "demoFileID", "0" );
	}
	
	level endon( "game_ended" );

	if ( isDefined( level.hostMigrationTimer ) )
		self thread maps\mp\gametypes\_hostmigration::hostMigrationTimerThink();
	
	if ( level.oldschool )
	{
		self.pers["class"] = undefined;
		self.class = self.pers["class"];
	}

	if ( isDefined( self.pers["team"] ) )
		self.team = self.pers["team"];

	if ( isDefined( self.pers["class"] ) )
		self.class = self.pers["class"];
		
	if ( !isDefined( self.pers["team"] ) || IsDefined( self.pers["needteam"] ) )
	{
		// Don't set .sessionteam until we've gotten the assigned team from code,
		// because it overrides the assigned team.
		self.pers["needteam"] = undefined;
		self.pers["team"] = "spectator";
		self.team = "spectator";
		self.sessionstate = "dead";
		
		self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();
		
		[[level.spawnSpectator]]();
		
		if ( level.rankedMatch )
		{
			[[level.autoassign]]();
			
			//self thread maps\mp\gametypes\_globallogic_spawn::forceSpawn();
			self thread maps\mp\gametypes\_globallogic_spawn::kickIfDontSpawn();
		}
		else if ( !level.teamBased )
		{
			[[level.autoassign]]();
		}
		else
		{
			if( ( isDefined( level.forceAutoAssign ) && level.forceAutoAssign ) || level.allow_teamchange != "1" )
			{
				[[level.autoassign]]();
			}
			else
			{
				self setclientdvar( "g_scriptMainMenu", game["menu_team"] );
				self openMenu( game["menu_team"] );
			}
		}
		
		if ( self.pers["team"] == "spectator" )
		{
			self.sessionteam = "spectator";
			if ( !level.teamBased ) 
				self.ffateam = "spectator";
		}
		
		if ( level.teamBased )
		{
			// set team and spectate permissions so the map shows waypoint info on connect
			self.sessionteam = self.pers["team"];
			if ( !isAlive( self ) )
				self.statusicon = "hud_status_dead";
			self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
		}
	}
	else if ( self.pers["team"] == "spectator" )
	{
		self setclientdvar( "g_scriptMainMenu", game["menu_team"] );
		[[level.spawnSpectator]]();
		self.sessionteam = "spectator";
		self.sessionstate = "spectator";
		if ( !level.teamBased ) 
			self.ffateam = "spectator";
		self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	}
	else
	{
		self.sessionteam = self.pers["team"];
		self.sessionstate = "dead";

		if ( !level.teamBased ) 
				self.ffateam = self.pers["team"];
		
		self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();
		
		[[level.spawnSpectator]]();
		
		if ( maps\mp\gametypes\_globallogic_utils::isValidClass( self.pers["class"] ) )
		{
			self thread [[level.spawnClient]]();			
		}
		else
		{
			self maps\mp\gametypes\_globallogic_ui::showMainMenuForTeam();
		}
		
		self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	}
	
	if( maps\mp\gametypes\_customClasses::isUsingCustomGameModeClasses() )
	{
		self thread maps\mp\gametypes\_customClasses::sprintSpeedModifier();
	}

	if ( isDefined( self.pers["isBot"] ) )
		return;
}

Callback_PlayerMigrated()
{
	println( "Player " + self.name + " finished migrating at time " + gettime() );
	
	if ( isDefined( self.connected ) && self.connected )
	{
		self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();
//		self updateObjectiveText();
//		self updateMainMenu();

//		if ( level.teambased )
//			self updateScores();
	}
	
	level.hostMigrationReturnedPlayerCount++;
	if ( level.hostMigrationReturnedPlayerCount >= level.players.size * 2 / 3 )
	{
		println( "2/3 of players have finished migrating" );
		level notify( "hostmigration_enoughplayers" );
	}
}

Callback_PlayerDisconnect()
{
	self removePlayerOnDisconnect();
	
	if ( !level.gameEnded )
		self maps\mp\gametypes\_globallogic_score::logXPGains();
	
	if ( level.splitscreen )
	{
		players = level.players;
		
		if ( players.size <= 1 )
			level thread maps\mp\gametypes\_globallogic::forceEnd();
			
		// passing number of players to menus in splitscreen to display leave or end game option
		setdvar( "splitscreen_playerNum", players.size );
	}

	if ( isDefined( self.score ) && isDefined( self.pers["team"] ) )
	{
		setPlayerTeamRank( self, level.dropTeam, self.score - 5 * self.deaths );
		self logString( "team: score " + self.pers["team"] + ":" + self.score );
		level.dropTeam += 1;
	}
	
	[[level.onPlayerDisconnect]]();
	
	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
	bbPrint( "mpquits: name %s client %d", self.name, lpselfnum );
	
	self maps\mp\_gamerep::gameRepPlayerDisconnected();
	
	for ( entry = 0; entry < level.players.size; entry++ )
	{
		if ( level.players[entry] == self )
		{
			while ( entry < level.players.size-1 )
			{
				level.players[entry] = level.players[entry+1];
				entry++;
			}
			level.players[entry] = undefined;
			break;
		}
	}	
	for ( entry = 0; entry < level.players.size; entry++ )
	{
		if ( isDefined( level.players[entry].pers["killed_players"][self.name] ) )
			level.players[entry].pers["killed_players"][self.name] = undefined;

		if ( isDefined( level.players[entry].killedPlayersCurrent[self.name] ) )
			level.players[entry].killedPlayersCurrent[self.name] = undefined;

		if ( isDefined( level.players[entry].pers["killed_by"][self.name] ) )
			level.players[entry].pers["killed_by"][self.name] = undefined;

		if ( isDefined( level.players[entry].pers["nemesis_tracking"][self.name] ) )
			level.players[entry].pers["nemesis_tracking"][self.name] = undefined;
		
		// player that disconnected was our nemesis
		if ( level.players[entry].pers["nemesis_name"] == self.name )
		{
			level.players[entry] chooseNextBestNemesis();
		}
	}

	if ( level.gameEnded )
		self maps\mp\gametypes\_globallogic::removeDisconnectedPlayerFromPlacement();
	
	level thread maps\mp\gametypes\_globallogic::updateTeamStatus();
}

chooseNextBestNemesis()
{
	nemesisArray = self.pers["nemesis_tracking"];
	nemesisArrayKeys = getArrayKeys( nemesisArray );
	nemesisAmount = 0;
	nemesisName = "";

	if ( nemesisArrayKeys.size > 0 )
	{
		for ( i = 0; i < nemesisArrayKeys.size; i++ )
		{
			nemesisArrayKey = nemesisArrayKeys[i];
			if ( nemesisArray[nemesisArrayKey] > nemesisAmount )
			{
				nemesisName = nemesisArrayKey;
				nemesisAmount = nemesisArray[nemesisArrayKey];
			}
			
		}
	}

	self.pers["nemesis_name"] = nemesisName;

	if ( nemesisName != "" )
	{
		playerIndex = 0;
		for( ; playerIndex < level.players.size; playerIndex++ )
		{
			if ( level.players[playerIndex].name == nemesisName )
			{
				nemesisPlayer = level.players[playerIndex];
				self.pers["nemesis_rank"] = nemesisPlayer.pers["rank"];
				self.pers["nemesis_rankIcon"] = nemesisPlayer.pers["rankxp"];
				self.pers["nemesis_xp"] = nemesisPlayer.pers["prestige"];
				self.pers["nemesis_xuid"] = nemesisPlayer GetXUID(true);
				break;
			}
		}
	}
	else
	{
		self.pers["nemesis_xuid"] = "";
	}
}

removePlayerOnDisconnect()
{
	for ( entry = 0; entry < level.players.size; entry++ )
	{
		if ( level.players[entry] == self )
		{
			while ( entry < level.players.size-1 )
			{
				level.players[entry] = level.players[entry+1];
				entry++;
			}
			level.players[entry] = undefined;
			break;
		}
	}
}

custom_gamemodes_modified_damage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
	// regular public matches should early out
	if ( level.onlinegame && !GetDvarInt( #"xblive_privatematch" ) )
	{
		return iDamage;
	}
	
	if( maps\mp\gametypes\_customClasses::isUsingCustomGameModeClasses() && isDefined( eAttacker ) )
	{
		if( maps\mp\gametypes\_class::isExplosiveDamage( sMeansOfDeath, sWeapon ) ) 
		{
			iDamage *= eAttacker maps\mp\gametypes\_customClasses::getExplosiveDamageModifier();
		}
		else
		{
			iDamage *= eAttacker maps\mp\gametypes\_customClasses::getDamageModifier();
		}
	}
	if( isdefined( eAttacker) &&  isDefined( eAttacker.damageModifier ) )
	{
		iDamage *= eAttacker.damageModifier;
	}
	if ( ( sMeansOfDeath == "MOD_PISTOL_BULLET" ) || ( sMeansOfDeath == "MOD_RIFLE_BULLET" ) )
	{
		iDamage = int( iDamage * GetDvarFloat( #"scr_game_bulletdamage" ) );
	}
	
	return iDamage;
}

custom_gamemodes_vampirism_health( iDamage, eAttacker )
{
	// regular public matches should early out
	if ( level.onlinegame && !GetDvarInt( #"xblive_privatematch" ) )
	{
		return 0;
	}
	
	return Int(iDamage * eAttacker maps\mp\gametypes\_customClasses::getHealthVampirismModifier());
}

figureOutAttacker( eAttacker )
{
	if ( isdefined(eAttacker) )
	{
		if( isai(eAttacker) && isDefined( eAttacker.script_owner ) )
		{
			team = self.team;
			
			if ( IsAi( self ) && IsDefined( self.aiteam ) )
			{
				team = self.aiteam;
			}

			if ( eAttacker.script_owner.team != team )
				eAttacker = eAttacker.script_owner;
		}
			
		if( eAttacker.classname == "script_vehicle" && isDefined( eAttacker.owner ) )
			eAttacker = eAttacker.owner;
		else if( eAttacker.classname == "auto_turret" && isDefined( eAttacker.owner ) )
			eAttacker = eAttacker.owner;
	}

	return eAttacker;
}

figureOutWeapon( sWeapon, eInflictor )
{
	// explosive barrel/car detection
	if ( sWeapon == "none" && isDefined( eInflictor ) )
	{
		if ( isDefined( eInflictor.targetname ) && eInflictor.targetname == "explodable_barrel" )
		{
			sWeapon = "explodable_barrel_mp";
		}
		else if ( isDefined( eInflictor.destructible_type ) && isSubStr( eInflictor.destructible_type, "vehicle_" ) )
		{
			sWeapon = "destructible_car_mp";
		}
	}

	return sWeapon;
}


handleFlameDamage( eAttacker, eInflictor, iDamage, sWeapon, sMeansOfDeath)
{
	switch( sWeapon )
	{
	case "none":
		if ( !self hasperk( "specialty_fireproof" ) )
		{
			self thread maps\mp\_burnplayer::walkedThroughFlames( eAttacker, eInflictor, sWeapon );		
		}
		break;
	case "m2_flamethrower_mp":
		if ( !self hasperk( "specialty_fireproof" ) )
		{
			self thread maps\mp\_burnplayer::burnedWithFlameThrower( sWeapon );		
		}
		break;
	case "napalm_mp":
		if ( !self hasperk( "specialty_fireproof" ) )
		{
			if (isdefined (level.minDamageRequiredForNapalmBurn) && iDamage > level.minDamageRequiredForNapalmBurn)
			{
				self thread maps\mp\_burnplayer::hitWithNapalmStrike(eAttacker, eInflictor, "MOD_BURNED" );			
			}
			else
			{
				self thread maps\mp\_burnplayer::walkedThroughFlames( eAttacker, eInflictor, sWeapon );	
			}
		}
		break;
	case "rottweil72_mp":
		//if ( !self hasperk( "specialty_fireproof" ) )
		//{
		//	self thread maps\mp\_burnplayer::burnedWithDragonsBreath( eAttacker, eInflictor, sWeapon );		
		//}
		break;

	default:
		if( GetSubStr( sWeapon, 0, 3 ) == "ft_" )
		{
			if ( !self hasperk( "specialty_fireproof" ) )
			{
				self thread maps\mp\_burnplayer::burnedWithFlameThrower( eAttacker, eInflictor, sWeapon );		
			}
		}
		break;
	}
}

Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	// create a class specialty checks; CAC:bulletdamage, CAC:armorvest
	iDamage = maps\mp\gametypes\_class::cac_modified_damage( self, eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc );
	iDamage = custom_gamemodes_modified_damage( self, eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc );
	
	iDamage = int(iDamage);
	self.iDFlags = iDFlags;
	self.iDFlagsTime = getTime();

	if ( game["state"] == "postgame" )
		return;
	
	if ( self.sessionteam == "spectator" )
		return; 
	
	if ( isDefined( self.canDoCombat ) && !self.canDoCombat )
		return;
	
	if ( isDefined( eAttacker ) && isPlayer( eAttacker ) )
	{
		if( isDefined( eAttacker.canDoCombat ) && !eAttacker.canDoCombat )
			return;

		if( eAttacker.team == "spectator" || ( isDefined( eAttacker.teamSwitchExploit ) && eAttacker.teamSwitchExploit ) )
		{
/#
				println( "teamSwitchExploit prevented damage from " + eAttacker.name + ".\n" );
#/				
				return;
		}
	}
	
	if ( isDefined( level.hostMigrationTimer ) )
		return;

	eAttacker = figureOutAttacker( eAttacker );

	pixbeginevent( "PlayerDamage flags/tweaks" );

	// Don't do knockback if the damage direction was not specified
	if( !isDefined( vDir ) )
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	self maps\mp\gametypes\_bot::bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc );
	
	friendly = false;
	// Todo MGordon - Fix this stat collection
	//self thread  maps\mp\gametypes\_globallogic_score::threadedSetStatLBByName( sWeapon, 1, "hits by", 2 );

	if ( ((self.health == self.maxhealth)) || !isDefined( self.attackers ) )
	{
		self.attackers = [];
		self.attackerData = [];
		self.attackerDamage = [];
		self.firstTimeDamaged = getTime();
	}
	// added check to notify chatter to play pain vo
	if (self.health != self.maxhealth)
	{
		self notify( "snd_pain_player" );
	}	

	if ( IsDefined( eInflictor) && IsDefined( eInflictor.script_noteworthy) && eInflictor.script_noteworthy == "ragdoll_now" )
	{
		sMeansOfDeath = "MOD_FALLING";
	}

	if ( maps\mp\gametypes\_globallogic_utils::isHeadShot( sWeapon, sHitLoc, sMeansOfDeath ) && isPlayer(eAttacker) )
	{
		//Turning off damage headshot sounds to avoid confusion from the killing headshot sound.
		//if (self.team != eAttacker.team)
		//{
		//	eAttacker playLocalSound( "prj_bullet_impact_headshot_helmet_nodie_2d" );	
		//}
		sMeansOfDeath = "MOD_HEAD_SHOT";
	}
	
	modifiedDamage = [[level.onPlayerDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime );
	if ( isDefined( modifiedDamage ) )
		iDamage = modifiedDamage;
	
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "game", "onlyheadshots" ) )
	{
		if ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" )
			return;
		else if ( sMeansOfDeath == "MOD_HEAD_SHOT" )
			iDamage = 150;
	}
	
	// Make all vehicle drivers invulnerable to bullets
	if ( self maps\mp\_vehicles::player_is_occupant_invulnerable( sMeansOfDeath ) )
		return;

	if (isdefined (eAttacker) && isPlayer(eAttacker) && (self.team != eAttacker.team))
	{
		self.lastAttackWeapon = sWeapon;

		if ( eAttacker maps\mp\_vehicles::player_is_driver() )
		{
			vehicle = eAttacker GetVehicleOccupied();
			self.lastTankThatAttacked = vehicle;
			self thread maps\mp\gametypes\_globallogic_vehicle::clearLastTankAttacker();
		}		

		// rottweil72 shoots dragon's breath rounds, so show a little fire on the player who got damaged
		if( sMeansOfDeath == "MOD_BURNED" || sWeapon == "rottweil72_mp" )
		{
			handleFlameDamage( eAttacker, eInflictor, iDamage, sWeapon, sMeansOfDeath);
		}
	}
		
	sWeapon = figureOutWeapon( sWeapon, eInflictor );

	pixendevent( "END: PlayerDamage flags/tweaks" );

	if( iDFlags & level.iDFLAGS_PENETRATION && isplayer ( eAttacker ) && eAttacker hasPerk( "specialty_bulletpenetration" ) )
		self thread maps\mp\gametypes\_battlechatter_mp::perkSpecificBattleChatter( "deepimpact", true );

	// check for completely getting out of the damage
	if( !(iDFlags & level.iDFLAGS_NO_PROTECTION) )
	{
		if( ( isSubStr( sMeansOfDeath, "MOD_GRENADE" ) || isSubStr( sMeansOfDeath, "MOD_EXPLOSIVE" ) || isSubStr( sMeansOfDeath, "MOD_PROJECTILE" ) || isSubStr( sMeansOfDeath, "MOD_GAS" ) ) && 
			isDefined( eInflictor ) )
		{
			// protect players from spawnkill grenades, tabun and incendiary
			if ( ( eInflictor.classname == "grenade" || sweapon == "tabun_gas_mp" )  && (self.lastSpawnTime + 3500) > getTime() && distance( eInflictor.origin, self.lastSpawnPoint.origin ) < 250 )
			{
//				pixmarker( "END: Callback_PlayerDamage player" );
				return;
			}
			
			self.explosiveInfo = [];
			self.explosiveInfo["damageTime"] = getTime();
			self.explosiveInfo["damageId"] = eInflictor getEntityNumber();
			self.explosiveInfo["returnToSender"] = false;
			self.explosiveInfo["bulletPenetrationKill"] = false;
			self.explosiveInfo["chainKill"]  = false;
			self.explosiveInfo["counterKill"] = false;
			self.explosiveInfo["chainKill"] = false;
			self.explosiveInfo["cookedKill"] = false;
			self.explosiveInfo["weapon"] = sWeapon;
			self.explosiveInfo["originalowner"] = eInflictor.originalowner;
			
			isFrag = isSubStr( sWeapon, "frag_" );

			if ( eAttacker != self )
			{
				if ( (isSubStr( sWeapon, "satchel_" ) || isSubStr( sWeapon, "claymore_" ) ) && isDefined( eAttacker ) && isDefined( eInflictor.owner ) )
				{
					self.explosiveInfo["returnToSender"] = (eInflictor.owner == self);
					self.explosiveInfo["counterKill"] = isDefined( eInflictor.wasDamaged );
					self.explosiveInfo["chainKill"] = isDefined( eInflictor.wasChained );
					self.explosiveInfo["ohnoyoudontKill"] = isDefined( eInflictor.wasJustPlanted );
					self.explosiveInfo["bulletPenetrationKill"] = isDefined( eInflictor.wasDamagedFromBulletPenetration );
					self.explosiveInfo["cookedKill"] = false;
				}
				if ( ( sWeapon == "sticky_grenade_mp" || sWeapon == "explosive_bolt_mp"  ) && isDefined( eInflictor ) && isdefined( eInflictor.stuckToPlayer ) )
				{
					self.explosiveInfo["stuckToPlayer"] = eInflictor.stuckToPlayer;
				}
				if ( isDefined( eAttacker.lastGrenadeSuicideTime ) && eAttacker.lastGrenadeSuicideTime >= gettime() - 50 && isFrag )
				{
					self.explosiveInfo["suicideGrenadeKill"] = true;
				}
				else
				{
					self.explosiveInfo["suicideGrenadeKill"] = false;
				}
			}
			
			if ( isFrag )
			{
				self.explosiveInfo["cookedKill"] = isDefined( eInflictor.isCooked );
				self.explosiveInfo["throwbackKill"] = isDefined( eInflictor.threwBack );
			}

			if( isPlayer( eAttacker ) && eAttacker != self )
			{
				self maps\mp\gametypes\_globallogic_score::setInflictorStat( eInflictor, eAttacker, sWeapon );
			}
		}

		if( isSubStr( sMeansOfDeath, "MOD_IMPACT" ) && isDefined( eAttacker ) && isPlayer( eAttacker ) && eAttacker != self )
		{
			if ( sWeapon != "knife_ballistic_mp" )
			{
				self maps\mp\gametypes\_globallogic_score::setInflictorStat( eInflictor, eAttacker, sWeapon );
			}

			if ( sWeapon == "hatchet_mp" && isDefined( eInflictor ) )
			{
				self.explosiveInfo["projectile_bounced"] = isDefined( eInflictor.bounced );
			}
		}
		
		if ( isPlayer( eAttacker ) )
			eAttacker.pers["participation"]++;
		
		prevHealthRatio = self.health / self.maxhealth;
		
		if ( level.teamBased && isPlayer( eAttacker ) && (self != eAttacker) && (self.team == eAttacker.team) )
		{
			pixmarker( "BEGIN: PlayerDamage player" ); // profs automatically end when the function returns
			if ( level.friendlyfire == 0 ) // no one takes damage
			{
				if ( sWeapon == "artillery_mp" || sWeapon == "airstrike_mp" || sWeapon == "napalm_mp" || sWeapon == "mortar_mp" )
					self damageShellshockAndRumble( eAttacker, eInflictor, sWeapon, sMeansOfDeath, iDamage );
				return;
			}
			else if ( level.friendlyfire == 1 ) // the friendly takes damage
			{
				// Make sure at least one point of damage is done
				if ( iDamage < 1 )
					iDamage = 1;

				//check for friendly fire at the begining of the match. apply the damage to the attacker only
				if( level.friendlyFireDelay && level.friendlyFireDelayTime >= ( ( ( gettime() - level.startTime ) - level.discardTime ) / 1000 ) )
				{
					eAttacker.lastDamageWasFromEnemy = false;
				
					eAttacker.friendlydamage = true;
					eAttacker finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
					eAttacker.friendlydamage = undefined;
				}
				else
				{
					self.lastDamageWasFromEnemy = false;
					
					self finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				}
			}
			else if ( level.friendlyfire == 2 && isAlive( eAttacker ) ) // only the attacker takes damage
			{
				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;
				
				eAttacker.lastDamageWasFromEnemy = false;
				
				eAttacker.friendlydamage = true;
				eAttacker finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
			}
			else if ( level.friendlyfire == 3 && isAlive( eAttacker ) ) // both friendly and attacker take damage
			{
				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if ( iDamage < 1 )
					iDamage = 1;
				
				self.lastDamageWasFromEnemy = false;
				eAttacker.lastDamageWasFromEnemy = false;
				
				self finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = true;
				eAttacker finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
			}
			
			friendly = true;
			pixmarker( "END: PlayerDamage player" );
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			if ( isDefined( eAttacker ) && isPlayer( eAttacker ) && allowedAssistWeapon( sWeapon ) )
			{				
				trackAttackerDamage( eAttacker, iDamage, sMeansOfDeath, sWeapon );
			}
		
			giveInflictorOwnerAssist( eAttacker, eInflictor, iDamage, sMeansOfDeath, sWeapon );
	
			if ( isdefined( eAttacker ) )
				level.lastLegitimateAttacker = eAttacker;

			if ( isdefined( eAttacker ) && isPlayer( eAttacker ) && isDefined( sWeapon ) && !issubstr( sMeansOfDeath, "MOD_MELEE" ) )
				eAttacker thread maps\mp\gametypes\_weapons::checkHit( sWeapon );

			if ( issubstr( sMeansOfDeath, "MOD_GRENADE" ) && isDefined( eInflictor.isCooked ) )
				self.wasCooked = getTime();
			else
				self.wasCooked = undefined;
			
			self.lastDamageWasFromEnemy = (isDefined( eAttacker ) && (eAttacker != self));

			if ( self.lastDamageWasFromEnemy )
				eAttacker.damagedPlayers[ self.clientId ] = getTime();
			
			self finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

			self thread maps\mp\gametypes\_missions::playerDamaged(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, sHitLoc );

			if ( isdefined ( eAttacker ) )
			{
				// if vampirism is on, give the attacker health as a % of damage done to the player
				eAttacker.health += custom_gamemodes_vampirism_health( iDamage, eAttacker );
			}
		}

		if ( isdefined(eAttacker) && isplayer( eAttacker ) && eAttacker != self )
		{			
			if ( doDamageFeedback( sWeapon, eInflictor ) )
			{
				hasBodyArmor = false;
				
				if ( iDamage > 0 )
				{
					// if the attacker has tactical mask pro then we show the special yellow indicator
					if( IsPlayer( eAttacker ) && eAttacker HasPerk( "specialty_shades" ) && eAttacker HasPerk( "specialty_stunprotection" ) && eAttacker HasPerk( "specialty_gas_mask" ) )
					{
						// show the yellow indicator if this is a flash or concussion grenade and they don't have tactical mask on
						if( sMeansOfDeath == "MOD_GRENADE_SPLASH" && 
							( sWeapon == "flash_grenade_mp" || sWeapon == "concussion_grenade_mp" ) && 
							( !self HasPerk( "specialty_shades" ) || !self HasPerk( "specialty_stunprotection" ) ) )
						{
							eAttacker thread maps\mp\gametypes\_damagefeedback::updateSpecialDamageFeedback( self );
						}
					}
					
					eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( hasBodyArmor, sMeansOfDeath );
				}
			}
		}
		
		self.hasDoneCombat = true;
	}

	if(self.sessionstate != "dead")
		self maps\mp\gametypes\_gametype_variants::onPlayerTakeDamage( eAttacker, eInflictor, sWeapon, iDamage, sMeansOfDeath );

	if ( isdefined( eAttacker ) && eAttacker != self && !friendly )
		level.useStartSpawns = false;

	pixbeginevent( "PlayerDamage log" );

	// Do debug print if it's enabled
	if(GetDvarInt( #"g_debugDamage"))
		println("client:" + self getEntityNumber() + " health:" + self.health + " attacker:" + eAttacker.clientid + " inflictor is player:" + isPlayer(eInflictor) + " damage:" + iDamage + " hitLoc:" + sHitLoc);

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfteam = self.team;
		lpselfGuid = self getGuid();
		lpattackerteam = "";
		lpattackerorigin = ( 0, 0, 0 );

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.team;
			lpattackerorigin = eAttacker.origin;
			bbPrint( "mpattacks: gametime %d attackerspawnid %d attackerweapon %s attackerx %f attackery %f attackerz %f victimspawnid %d victimx %f victimy %f victimz %f damage %d damagetype %s damagelocation %s death 0",
				           gettime(), getplayerspawnid( eAttacker ), sWeapon, lpattackerorigin, getplayerspawnid( self ), self.origin, iDamage, sMeansOfDeath, sHitLoc ); 
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
			bbPrint( "mpattacks: gametime %d attackerweapon %s victimspawnid %d victimx %f victimy %f victimz %f damage %d damagetype %s damagelocation %s death 0",
				           gettime(), sWeapon, getplayerspawnid( self ), self.origin, iDamage, sMeansOfDeath, sHitLoc ); 
		}
		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
	
/#
	if ( GetDvarInt( #"scr_hitloc_debug") )
	{
		if ( !isdefined( eAttacker.hitlocInited ) )
		{
			for ( i = 0; i < 6; i++ )
			{
				eAttacker setClientDvar( "ui_hitloc_" + i, "" );
			}
			eAttacker.hitlocInited = true;
		}
		
		if ( isPlayer( eAttacker ) && !level.splitscreen )
		{
			colors = [];
			colors[0] = 2;
			colors[1] = 3;
			colors[2] = 5;
			colors[3] = 7;
			
			elemcount = 6;
			if ( !isdefined( eAttacker.damageInfo ) )
			{
				eAttacker.damageInfo = [];
				for ( i = 0; i < elemcount; i++ )
				{
					eAttacker.damageInfo[i] = spawnstruct();
					eAttacker.damageInfo[i].damage = 0;
					eAttacker.damageInfo[i].hitloc = "";
					eAttacker.damageInfo[i].bp = false;
					eAttacker.damageInfo[i].jugg = false;
					eAttacker.damageInfo[i].colorIndex = 0;
				}
				eAttacker.damageInfoColorIndex = 0;
				eAttacker.damageInfoVictim = undefined;
			}
			
			for ( i = elemcount-1; i > 0; i-- )
			{
				eAttacker.damageInfo[i].damage = eAttacker.damageInfo[i - 1].damage;
				eAttacker.damageInfo[i].hitloc = eAttacker.damageInfo[i - 1].hitloc;
				eAttacker.damageInfo[i].bp = eAttacker.damageInfo[i - 1].bp;
				eAttacker.damageInfo[i].jugg = eAttacker.damageInfo[i - 1].jugg;
				eAttacker.damageInfo[i].colorIndex = eAttacker.damageInfo[i - 1].colorIndex;
			}
			eAttacker.damageInfo[0].damage = iDamage;
			eAttacker.damageInfo[0].hitloc = sHitLoc;
			eAttacker.damageInfo[0].bp = (iDFlags & level.iDFLAGS_PENETRATION);
			eAttacker.damageInfo[0].jugg = false;
			if ( isdefined( eAttacker.damageInfoVictim ) && eAttacker.damageInfoVictim != self )
			{ 
				eAttacker.damageInfoColorIndex++;
				if ( eAttacker.damageInfoColorIndex == colors.size )
					eAttacker.damageInfoColorIndex = 0;
			}
			eAttacker.damageInfoVictim = self;
			eAttacker.damageInfo[0].colorIndex = eAttacker.damageInfoColorIndex;
			
			for ( i = 0; i < elemcount; i++ )
			{
				color = "^" + colors[ eAttacker.damageInfo[i].colorIndex ];
				if ( eAttacker.damageInfo[i].hitloc != "" )
				{
					val = color + eAttacker.damageInfo[i].hitloc;
					if ( eAttacker.damageInfo[i].bp )
						val += " (BP)";
					if ( eAttacker.damageInfo[i].jugg  )
						val += " (Jugg)";
					eAttacker setClientDvar( "ui_hitloc_" + i, val );
				}
				eAttacker setClientDvar( "ui_hitloc_damage_" + i, color + eAttacker.damageInfo[i].damage );
			}
		}
	}
#/	
	pixendevent( "END: PlayerDamage log" );
}

resetAttackerList()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self.attackers = [];
	self.attackerData = [];
	self.attackerDamage = [];
}

doDamageFeedback( sWeapon, eInflictor )
{
	if ( !IsDefined( sWeapon ) )
		return false;
		
	switch(sWeapon)
	{
		case "artillery_mp":
		case "airstrike_mp":
		case "napalm_mp":
		case "mortar_mp":
		case "tow_turret_mp":
		case "auto_gun_turret_mp":
		case "cobra_20mm_comlink_mp":
			return false;
	}
		
	if ( IsDefined( eInflictor ) )
	{
		if ( IsAI(eInflictor) )
		{
			return false;
		}
	}
	
	return true;
}

doPrintDamage(dmg, hitloc)
{
	huddamage = newclienthudelem(self);
  huddamage.alignx = "center";
  huddamage.horzalign = "center";
  huddamage.x = 10;
  huddamage.y = 235;
  huddamage.fontscale = 1.6;
  huddamage.font = "objective";
  huddamage setvalue(dmg);

  if (hitloc == "head")
    huddamage.color = (1, 1, 0.25);

  huddamage moveovertime(1);
  huddamage fadeovertime(1);
  huddamage.alpha = 0;
  huddamage.x = randomIntRange(25, 70);

	val = 1;
	if (cointoss())
		val = -1;
	
  huddamage.y = 235 + randomIntRange(25, 70) * val;

  wait 1;

	huddamage destroy();
}

finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{	
	pixbeginevent("finishPlayerDamageWrapper");

	if ( isDefined( eAttacker ) && isPlayer( eAttacker ) )
		eAttacker thread doPrintDamage(iDamage, sHitLoc);
	else if( isDefined( eAttacker.owner ) && isPlayer( eAttacker.owner ) )
		eAttacker.owner thread doPrintDamage(iDamage, sHitLoc);

	surface = "flesh";
	
	if ( self.cac_body_type == "body_armor_mp" )
	{
		surface = "metal";
	}
	
	self finishPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, surface );
	
	if ( GetDvar( #"scr_csmode" ) != "" )
		self shellShock( "damage_mp", 0.2 );
	
	self damageShellshockAndRumble( eAttacker, eInflictor, sWeapon, sMeansOfDeath, iDamage );
	pixendevent();
}

allowedAssistWeapon( weapon )
{
	if ( !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( weapon ) )
		return true;
		
	if (maps\mp\gametypes\_hardpoints::isKillstreakWeaponAssistAllowed(  weapon ) )
		return true;
		
	return false;
}

GiveCustomGameModePlayerKilledScore( attacker, sMeansOfDeath )
{
	if( !maps\mp\gametypes\_customClasses::isCustomGame() )
		return;

	if( level.gameType != "tdm" && level.gameType != "dm" )
		return;

	if( isDefined( attacker ) && ( self == attacker || ( attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" ) ) )
	{
		maps\mp\gametypes\_globallogic_score::givePlayerScore( "suicide", self, self );
		maps\mp\gametypes\_globallogic_score::giveTeamScore( "suicide", self.team, self, self );
		return; // no other bonuses if you're suicidin'
	}

	if( sMeansOfDeath == "MOD_HEAD_SHOT" )
	{
		maps\mp\gametypes\_globallogic_score::givePlayerScore( "headshot", attacker, self );
		maps\mp\gametypes\_globallogic_score::giveTeamScore( "headshot", attacker.team, attacker, self );
	}
	if( isDefined( level.placement ) )
	{
		maps\mp\gametypes\_globallogic::updatePlacement();
		if( attacker maps\mp\gametypes\_customClasses::shouldGiveLeaderBonus() )
		{
			leaderbonus = getDvarInt( "scr_" + level.gameType + "_bonus_leader" );
			if( isDefined( leaderBonus ) )
			{
				maps\mp\gametypes\_globallogic_score::_setPlayerScore( attacker, attacker.pers["score"] + leaderBonus );
				maps\mp\gametypes\_globallogic_score::onTeamScore( leaderBonus, attacker.team, attacker, self );
				maps\mp\gametypes\_globallogic_score::updateTeamScores( attacker.team );
			}
		}
	}
	maps\mp\gametypes\_globallogic_score::givePlayerScore( "death", self, self );
	maps\mp\gametypes\_globallogic_score::giveTeamScore( "death", self.team, self, self );

}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon( "spawned" );
	self notify( "killed_player" );

	if ( self.sessionteam == "spectator" )
		return;
	
	if ( game["state"] == "postgame" )
		return;	

	self needsRevive( false );

	if ( isdefined( self.burning ) && self.burning == true )
	{
		self setburn( 0 );
	}

	self.suicide = false;
	
	if ( isDefined( level.takeLivesOnDeath ) && ( level.takeLivesOnDeath == true ) )
	{
		if ( self.pers["lives"] )
		{
			self.pers["lives"]--;
			if ( self.pers["lives"] == 0 )
			{
				level notify( "player_eliminated" );
				self notify( "player_eliminated" );
			}

		}
	}

	sWeapon = updateWeapon( eInflictor, sWeapon );
	
	pixbeginevent( "PlayerKilled pre constants" );
	
	wasInLastStand = false;
	deathTimeOffset = 0;
	lastWeaponBeforeDroppingIntoLastStand = undefined;
	attackerStance = undefined;
	self.lastStandThisLife = undefined;
	self.vAttackerOrigin = undefined;
					
	if ( isdefined( self.useLastStandParams ) )
	{
		self.useLastStandParams = undefined;
		
		assert( isdefined( self.lastStandParams ) );
		if ( !level.teamBased || ( !isDefined( attacker ) || !isplayer( attacker ) || attacker.team != self.team || attacker == self ) )
		{
			eInflictor = self.lastStandParams.eInflictor;
			attacker = self.lastStandParams.attacker;
			attackerStance = self.lastStandParams.attackerStance;
			iDamage = self.lastStandParams.iDamage;
			sMeansOfDeath = self.lastStandParams.sMeansOfDeath;
			sWeapon = self.lastStandParams.sWeapon;
			vDir = self.lastStandParams.vDir;
			sHitLoc = self.lastStandParams.sHitLoc;
			self.vAttackerOrigin = self.lastStandParams.vAttackerOrigin;
			deathTimeOffset = (gettime() - self.lastStandParams.lastStandStartTime) / 1000;
			
			self thread maps\mp\gametypes\_battlechatter_mp::perkSpecificBattleChatter( "secondchance" );
			
			if ( isDefined( self.previousPrimary ) )
			{
				wasInLastStand = true;
				lastWeaponBeforeDroppingIntoLastStand = self.previousPrimary;
			}
		}
		self.lastStandParams = undefined;
	}

	bestPlayer = undefined;
	bestPlayerMeansOfDeath = undefined;
	obituaryMeansOfDeath = undefined;
	bestPlayerWeapon = undefined;
	obituaryWeapon = undefined;

	if ( (!isDefined( attacker ) || attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" || ( isdefined( attacker.isMagicBullet ) && attacker.isMagicBullet == true ) || attacker == self ) && isDefined( self.attackers )  )
	{		
		if ( !isDefined(bestPlayer) )
		{
			for ( i = 0; i < self.attackers.size; i++ )
			{
				player = self.attackers[i];
				if ( !isDefined( player ) )
					continue;
				
				if (!isDefined( self.attackerDamage[ player.clientId ] ) || ! isDefined( self.attackerDamage[ player.clientId ].damage ) )
					continue;
				
				if ( player == self || (level.teamBased && player.team == self.team ) )
					continue;
				
				if ( self.attackerDamage[ player.clientId ].lasttimedamaged + 2500 < getTime() )
					continue;			
	
				if ( !allowedAssistWeapon( self.attackerDamage[ player.clientId ].weapon ) )
					continue;
	
				if ( self.attackerDamage[ player.clientId ].damage > 1 && ! isDefined( bestPlayer ) )
				{
					bestPlayer = player;
					bestPlayerMeansOfDeath = self.attackerDamage[ player.clientId ].meansOfDeath;
					bestPlayerWeapon = self.attackerDamage[ player.clientId ].weapon;
				}
				else if ( isDefined( bestPlayer ) && self.attackerDamage[ player.clientId ].damage > self.attackerDamage[ bestPlayer.clientId ].damage )
				{
					bestPlayer = player;	
					bestPlayerMeansOfDeath = self.attackerDamage[ player.clientId ].meansOfDeath;
					bestPlayerWeapon = self.attackerDamage[ player.clientId ].weapon;
				}
			}
		}
		if ( isdefined ( bestPlayer ) )	
			bestPlayer maps\mp\_medals::assistedSuicide(bestPlayerWeapon);
	}
	
	if ( isdefined ( bestPlayer ) )
	{
		attacker = bestPlayer;
		obituaryMeansOfDeath = bestPlayerMeansOfDeath;
		obituaryWeapon = bestPlayerWeapon;
	}

	if ( isplayer( attacker ) )
		attacker.damagedPlayers[self.clientid] = undefined;

	if( maps\mp\gametypes\_globallogic_utils::isHeadShot( sWeapon, sHitLoc, sMeansOfDeath ) && isPlayer( attacker ) )
	{
		attacker playLocalSound( "prj_bullet_impact_headshot_helmet_nodie_2d" );
		//attacker playLocalSound( "prj_bullet_impact_headshot_2d" );

		sMeansOfDeath = "MOD_HEAD_SHOT";
	}
	
	self.deathTime = getTime();
		
	attacker = updateAttacker( attacker );
	eInflictor = updateInflictor( eInflictor );

	sMeansOfDeath = updateMeansOfDeath( sWeapon, sMeansOfDeath );
	
	self thread updateGlobalBotKilledCounter();
	if ( maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) )
	{
		level.globalKillstreaksDeathsFrom++;
	}

	// Don't increment weapon stats for team kills or deaths
	if ( isPlayer( attacker ) && attacker != self && ( !level.teamBased || ( level.teamBased && self.team != attacker.team ) ) )
	{
		self thread  maps\mp\gametypes\_globallogic_score::trackLeaderBoardDeathStats( sWeapon, sMeansOfDeath ); 

		if ( wasInLastStand && isDefined( lastWeaponBeforeDroppingIntoLastStand ) ) 
			weaponName = lastWeaponBeforeDroppingIntoLastStand;
		else
			weaponName = self.lastdroppableweapon;

		if ( isDefined( weaponName ) && ( isSubStr( weaponName, "gl_" ) || isSubStr( weaponName, "mk_" ) || isSubStr( weaponName, "ft_" ) ) )
			weaponName = self.currentWeapon;
	
		if ( isDefined( weaponName ) )
			self thread  maps\mp\gametypes\_globallogic_score::trackLeaderBoardDeathsDuringUseStats( weaponName );

		attacker thread  maps\mp\gametypes\_globallogic_score::trackAttackerLeaderBoardDeathStats( sWeapon, sMeansOfDeath ); 
	}
	
	if ( !isdefined( obituaryMeansOfDeath ) ) 
		obituaryMeansOfDeath = sMeansOfDeath;
	if ( !isdefined( obituaryWeapon ) ) 
		obituaryWeapon = sWeapon;

	// send out an obituary message to all clients about the kill
	if( level.teamBased && isDefined( attacker.pers ) && self.team == attacker.team && obituaryMeansOfDeath == "MOD_GRENADE" && level.friendlyfire == 0 )
	{
		obituary(self, self, obituaryWeapon, obituaryMeansOfDeath);
		maps\mp\_demo::bookmark( "kill", gettime(), self, self );
	}
	else
	{
		obituary(self, attacker, obituaryWeapon, obituaryMeansOfDeath);
		maps\mp\_demo::bookmark( "kill", gettime(), self, attacker );
	}

//	self maps\mp\gametypes\_weapons::updateWeaponUsageStats();
	if ( !level.inGracePeriod )
	{
		self maps\mp\gametypes\_weapons::dropScavengerForDeath( attacker );
		self maps\mp\gametypes\_weapons::dropWeaponForDeath( attacker );
		self maps\mp\gametypes\_weapons::dropOffhand();
	}

	maps\mp\gametypes\_spawnlogic::deathOccured(self, attacker);

	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";

	self.pers["weapon"] = undefined;
	
	self.killedPlayersCurrent = [];
	
	self.deathCount++;

/#
	println( "players("+self.clientId+") death count ++: " + self.deathCount );
#/

	if( !isDefined( self.switching_teams ) )
	{
		// if team killed we reset kill streak, but dont count death and death streak
		if ( isPlayer( attacker ) && level.teamBased && ( attacker != self ) && ( self.team == attacker.team ) )
		{		
								
			self.pers["cur_kill_streak"] = 0;
			self.pers["totalKillstreakCount"] = 0;
			self.pers["killstreaksEarnedThisKillstreak"] = 0;
		}
		else
		{		
			self  maps\mp\gametypes\_globallogic_score::incPersStat( "deaths", 1, true, true );
			self.deaths = self  maps\mp\gametypes\_globallogic_score::getPersStat( "deaths" );	
			self  maps\mp\gametypes\_globallogic_score::updatePersRatio( "kdratio", "kills", "deaths" );

			if( self.pers["cur_kill_streak"] > self.pers["best_kill_streak"] )
				self.pers["best_kill_streak"] = self.pers["cur_kill_streak"];

			// need to keep the current killstreak to see if this was a buzzkill later
			self.pers["kill_streak_before_death"] = self.pers["cur_kill_streak"];

			self.pers["cur_kill_streak"] = 0;
			self.pers["totalKillstreakCount"] = 0;
			self.pers["killstreaksEarnedThisKillstreak"] = 0;

			self.cur_death_streak++;

			if ( self.cur_death_streak > self.death_streak )
			{
				self setDStat( "HighestStats", "death_streak", self.cur_death_streak );
				self.death_streak = self.cur_death_streak;
			}
			
			if( self.cur_death_streak >= GetDvarInt( #"perk_deathStreakCountRequired" ) )
			{
				self enabledeathstreak();
			}
		}
	}
	else
	{
		self.pers["totalKillstreakCount"] = 0;
		self.pers["killstreaksEarnedThisKillstreak"] = 0;
	}
	
	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpattackGuid = "";
	lpattackname = "";
	lpselfteam = self.team;
	lpselfguid = self getGuid();
	lpattackteam = "";
	lpattackorigin = ( 0, 0, 0 );

	lpattacknum = -1;

	//check if we should award assist points
	awardAssists = false;

	pixendevent(); // "PlayerKilled pre constants" );

	self GiveCustomGameModePlayerKilledScore( attacker, sMeansOfDeath );

	if( isPlayer( attacker ) )
	{
		lpattackGuid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackteam = attacker.team;
		lpattackorigin = attacker.origin;

		if ( attacker == self ) // killed himself
		{
			doKillcam = false;
			
			// switching teams
			if ( isDefined( self.switching_teams ) )
			{
				if ( !level.teamBased && ((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies")) )
				{
					playerCounts = self maps\mp\gametypes\_teams::CountPlayers();
					playerCounts[self.leaving_team]--;
					playerCounts[self.joining_team]++;
				
					if( (playerCounts[self.joining_team] - playerCounts[self.leaving_team]) > 1 )
					{
						self thread [[level.onXPEvent]]( "suicide" );
						self  maps\mp\gametypes\_globallogic_score::incPersStat( "suicides", 1 );
						self.suicides = self  maps\mp\gametypes\_globallogic_score::getPersStat( "suicides" );
					}
				}
			}
			else
			{
				self thread [[level.onXPEvent]]( "suicide" );
				self  maps\mp\gametypes\_globallogic_score::incPersStat( "suicides", 1 );
				self.suicides = self  maps\mp\gametypes\_globallogic_score::getPersStat( "suicides" );

				if ( sMeansOfDeath == "MOD_SUICIDE" && sHitLoc == "none" && self.throwingGrenade )
				{
					self.lastGrenadeSuicideTime = gettime();
				}

				//Check for player death related battlechatter
				thread maps\mp\gametypes\_battlechatter_mp::onPlayerSuicideOrTeamKill( self, "suicide" );	//Play suicide battlechatter
				
				//check if assist points should be awarded
				awardAssists = true;
				self.suicide = true;
			}
			
			if( isDefined( self.friendlydamage ) )
			{
				self iPrintLn(&"MP_FRIENDLY_FIRE_WILL_NOT");
				if ( maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillpointloss" ) )
					{
						scoreSub = self [[level.getTeamKillScore]]( eInflictor, attacker, sMeansOfDeath, sWeapon);
						maps\mp\gametypes\_globallogic_score::_setPlayerScore( attacker,maps\mp\gametypes\_globallogic_score::_getPlayerScore( attacker ) - scoreSub );
					}
			}
		}
		else
		{
			pixbeginevent( "PlayerKilled attacker" );

			lpattacknum = attacker getEntityNumber();

			doKillcam = true;
			
			self thread maps\mp\gametypes\_gametype_variants::playerKilled( attacker );

			if ( level.teamBased && self.team == attacker.team && sMeansOfDeath == "MOD_GRENADE" && level.friendlyfire == 0 )
			{		
			}
			else if ( level.teamBased && self.team == attacker.team ) // killed by a friendly
			{
				attacker thread [[level.onXPEvent]]( "teamkill" );
		
				if ( !IgnoreTeamKills( sWeapon, sMeansOfDeath ) )
				{
					teamkill_penalty = self [[level.getTeamKillPenalty]]( eInflictor, attacker, sMeansOfDeath, sWeapon);
				
					attacker  maps\mp\gametypes\_globallogic_score::incPersStat( "teamkills_nostats", teamkill_penalty, false );
					attacker  maps\mp\gametypes\_globallogic_score::incPersStat( "teamkills", 1 ); //save team kills to player stats
					attacker.teamkillsThisRound++;
				
					if ( maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillpointloss" ) )
					{
						scoreSub = self [[level.getTeamKillScore]]( eInflictor, attacker, sMeansOfDeath, sWeapon);
						maps\mp\gametypes\_globallogic_score::_setPlayerScore( attacker,maps\mp\gametypes\_globallogic_score::_getPlayerScore( attacker ) - scoreSub );
					}
					
					if ( maps\mp\gametypes\_globallogic_utils::getTimePassed() < 5000 )
						teamKillDelay = 1;
					else if ( attacker.pers["teamkills_nostats"] > 1 && maps\mp\gametypes\_globallogic_utils::getTimePassed() < (8000 + (attacker.pers["teamkills_nostats"] * 1000)) )
						teamKillDelay = 1;
					else
						teamKillDelay = attacker TeamKillDelay();
						
					if ( teamKillDelay > 0 )
					{
						attacker.teamKillPunish = true;
						attacker suicide();
						
						if ( attacker ShouldTeamKillKick(teamKillDelay) )
						{
							attacker TeamKillKick();
						}
	
						attacker thread reduceTeamKillsOverTime();			
					}
	
					//Play teamkill battlechatter
					if( isPlayer( attacker ) )
						thread maps\mp\gametypes\_battlechatter_mp::onPlayerSuicideOrTeamKill( attacker, "teamkill" );
				}
			}
			else
			{
				maps\mp\gametypes\_globallogic_score::incTotalKills(attacker.team);
				
				attacker thread maps\mp\gametypes\_globallogic_score::giveKillStats( sMeansOfDeath, sWeapon, self );

				self maps\mp\gametypes\_copycat::copycat_clone_loadout( attacker );

				if ( isAlive( attacker ) )
				{
					pixbeginevent("killstreak");

					if ( !isDefined( eInflictor ) || !isDefined( eInflictor.requiredDeathCount ) || attacker.deathCount == eInflictor.requiredDeathCount )
					{
						shouldGiveKillstreak = maps\mp\gametypes\_hardpoints::shouldGiveKillstreak( sWeapon );
						attacker thread maps\mp\_properks::earnedAKill();

						if ( shouldGiveKillstreak )
						{
							attacker maps\mp\gametypes\_hardpoints::addToKillstreakCount(sWeapon);
						}
						
						//Kills gotten through killstreak weapons should not the players killstreak
						if ( isDefined( level.killstreaks ) &&  shouldGiveKillstreak )
						{	
							attacker.pers["cur_kill_streak"]++;
							attacker thread maps\mp\_properks::checkKillCount();
							attacker thread maps\mp\gametypes\_hardpoints::giveKillstreakForStreak();
						}
					}
				
					if( isPlayer( attacker ) )
						self thread maps\mp\gametypes\_battlechatter_mp::onPlayerKillstreak( attacker );
						
					pixendevent(); // "killstreak"
				}
 

				if ( attacker.pers["cur_kill_streak"] > attacker.kill_streak )
				{
					attacker setDStat( "HighestStats", "kill_streak", attacker.pers["totalKillstreakCount"] );
					attacker.kill_streak = attacker.pers["cur_kill_streak"];
				}
				

				if ( attacker.pers["cur_kill_streak"] > attacker.gametype_kill_streak )
				{
					attacker maps\mp\gametypes\_persistence::statSetWithGametype( "kill_streak", attacker.pers["cur_kill_streak"] );
					attacker.gametype_kill_streak = attacker.pers["cur_kill_streak"];
				}
				
				maps\mp\gametypes\_globallogic_score::givePlayerScore( "kill", attacker, self );

				attacker thread  maps\mp\gametypes\_globallogic_score::trackAttackerKill( self.name, self.pers["rank"], self.pers["rankxp"], self.pers["prestige"], self getXuid(true) );	
				
				attackerName = attacker.name;
				self thread  maps\mp\gametypes\_globallogic_score::trackAttackeeDeath( attackerName, attacker.pers["rank"], attacker.pers["rankxp"], attacker.pers["prestige"], attacker getXuid(true) );
				self thread maps\mp\_medals::setLastKilledBy( attacker );

				attacker thread  maps\mp\gametypes\_globallogic_score::incKillstreakTracker( sWeapon );
				
				// to prevent spectator gain score for team-spectator after throwing a granade and killing someone before he switched
				if ( level.teamBased && attacker.team != "spectator")
				{
					// dog score for team
					if( isai(Attacker) )
						maps\mp\gametypes\_globallogic_score::giveTeamScore( "kill", attacker.aiteam, attacker, self );
					else
						maps\mp\gametypes\_globallogic_score::giveTeamScore( "kill", attacker.team, attacker, self );
				}

				scoreSub = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "deathpointloss" );
				if ( scoreSub != 0 )
				{
					maps\mp\gametypes\_globallogic_score::_setPlayerScore( self, maps\mp\gametypes\_globallogic_score::_getPlayerScore( self ) - scoreSub );
				}
				
				level thread playKillBattleChatter( attacker, sWeapon );
				
				if ( level.teamBased )
				{
					//check if assist points should be awarded
					awardAssists = true;
				}
			}
			
			pixendevent( "PlayerKilled attacker" );
		}
	}
	else if ( isDefined( attacker ) && ( attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" ) )
	{
		doKillcam = false;

		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";
		lpattackteam = "world";

		self thread [[level.onXPEvent]]( "suicide" );
		self  maps\mp\gametypes\_globallogic_score::incPersStat( "suicides", 1 );
		self.suicides = self  maps\mp\gametypes\_globallogic_score::getPersStat( "suicides" );

		//Check for player death related battlechatter
		thread maps\mp\gametypes\_battlechatter_mp::onPlayerSuicideOrTeamKill( self, "suicide" );	//Play suicide battlechatter

		//check if assist points should be awarded
		awardAssists = true;

	}
	else
	{
		doKillcam = false;
		
		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";
		lpattackteam = "world";

		// we may have a killcam on an world entity like the rocket in cosmodrome
		if ( IsDefined( eInflictor ) && IsDefined( eInflictor.killCamEnt ) )
		{
			doKillcam = true;
			lpattacknum = self getEntityNumber();
		}

		// even if the attacker isn't a player, it might be on a team
		if ( isDefined( attacker ) && isDefined( attacker.team ) && (attacker.team == "axis" || attacker.team == "allies") )
		{
			if ( attacker.team != self.team ) 
			{
				if ( level.teamBased )
					maps\mp\gametypes\_globallogic_score::giveTeamScore( "kill", attacker.team, attacker, self );
			}
		}
		//check if assist points should be awarded
		awardAssists = true;
		
	}	
	
	//award assist points if needed
	if( awardAssists )
	{
		pixbeginevent( "PlayerKilled assists" );
					
			if ( isdefined( self.attackers ) )
			{
				for ( j = 0; j < self.attackers.size; j++ )
				{
					player = self.attackers[j];
					
					if ( !isDefined( player ) )
						continue;
					
					if ( player == attacker )
						continue;
					
					damage_done = self.attackerDamage[player.clientId].damage;
					player thread maps\mp\gametypes\_globallogic_score::processAssist( self, damage_done);
				}
			}
			
		pixendevent( "END: PlayerKilled assists" );
	}

	pixbeginevent( "PlayerKilled post constants" );

	self.lastAttacker = attacker;
	self.lastDeathPos = self.origin;

	if ( isDefined( attacker ) && isPlayer( attacker ) && attacker != self && (!level.teambased || attacker.team != self.team) )
	{
		self thread maps\mp\gametypes\_missions::playerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sHitLoc, attackerStance );
	}
	else
	{

		self notify("playerKilledChallengesProcessed");
	}

	if ( isdefined ( self.attackers ))
		self.attackers = [];
	if( isPlayer( attacker ) )
	{
		if( maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) )
		{
			killstreak = maps\mp\gametypes\_hardpoints::getKillstreakForWeapon( sWeapon );
			bbPrint( "mpattacks: gametime %d attackerspawnid %d attackerweapon %s attackerx %f attackery %f attackerz %f victimspawnid %d victimx %f victimy %f victimz %f damage %d damagetype %s damagelocation %s death 1 killstreak %s",
			           gettime(), getplayerspawnid( attacker ), sWeapon, lpattackorigin, getplayerspawnid( self ), self.origin, iDamage, sMeansOfDeath, sHitLoc, killstreak );
		}
		else
		{
			bbPrint( "mpattacks: gametime %d attackerspawnid %d attackerweapon %s attackerx %f attackery %f attackerz %f victimspawnid %d victimx %f victimy %f victimz %f damage %d damagetype %s damagelocation %s death 1",
			           	gettime(), getplayerspawnid( attacker ), sWeapon, lpattackorigin, getplayerspawnid( self ), self.origin, iDamage, sMeansOfDeath, sHitLoc );
		}
	}
	else
	{
		bbPrint( "mpattacks: gametime %d attackerweapon %s victimspawnid %d victimx %f victimy %f victimz %f damage %d damagetype %s damagelocation %s death 1",
			           gettime(), sWeapon, getplayerspawnid( self ), self.origin, iDamage, sMeansOfDeath, sHitLoc );
	}

	logPrint( "K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n" );
	attackerString = "none";
	if ( isPlayer( attacker ) ) // attacker can be the worldspawn if it's not a player
		attackerString = attacker getXuid() + "(" + lpattackname + ")";
	self logstring( "d " + sMeansOfDeath + "(" + sWeapon + ") a:" + attackerString + " d:" + iDamage + " l:" + sHitLoc + " @ " + int( self.origin[0] ) + " " + int( self.origin[1] ) + " " + int( self.origin[2] ) );

	level thread maps\mp\gametypes\_globallogic::updateTeamStatus();

	killcamentity = self getKillcamEntity( attacker, eInflictor, sWeapon );
	killcamentityindex = -1;
	killcamentitystarttime = 0;

	if ( isDefined( killcamentity ) )
	{
		killcamentityindex = killcamentity getEntityNumber(); // must do this before any waiting lest the entity be deleted
		if ( isdefined( killcamentity.startTime ) )
		{
			killcamentitystarttime = killcamentity.startTime;
		}
		else
		{
			killcamentitystarttime = killcamentity.birthtime;
		}
		if ( !isdefined( killcamentitystarttime ) )
			killcamentitystarttime = 0;
	}

	if ( self IsRemoteControlling() )
		doKillcam = false;

	self maps\mp\gametypes\_weapons::detachCarryObjectModel();
	
	died_in_vehicle= false;
	if (IsDefined(self.diedOnVehicle))
	{
		died_in_vehicle = self.diedOnVehicle;	// only works when vehicle blows up
	}
	pixendevent( "END: PlayerKilled post constants" );

	pixbeginevent( "PlayerKilled body and gibbing" );
	if ( !died_in_vehicle )
	{
		vAttackerOrigin = undefined;
		if ( isdefined( attacker ) )
			vAttackerOrigin = attacker.origin;
		
		ragdoll_now = false;
		if( IsDefined(self.usingvehicle) && self.usingvehicle && IsDefined(self.vehicleposition) && self.vehicleposition == 1 )
			ragdoll_now = true;
	
		if ( sMeansOfDeath == "MOD_FALLING" )
		{
			if ( IsDefined( eInflictor ) && IsDefined( eInflictor.script_noteworthy ) && eInflictor.script_noteworthy == "ragdoll_now" )
			{
				ragdoll_now = true;
				self thread maps\mp\_challenges::fellOffTheMap();
			}
		}
		
		body = self clonePlayer( deathAnimDuration );
		self createDeadBody( iDamage, sMeansOfDeath, sWeapon, sHitLoc, vDir, vAttackerOrigin, deathAnimDuration, eInflictor, ragdoll_now, body );
	}
	pixendevent( "END: PlayerKilled body and gibbing" );

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	self thread [[level.onPlayerKilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);

	for ( iCB = 0; iCB < level.onPlayerKilledExtraUnthreadedCBs.size; iCB++ )
	{
		self [[ level.onPlayerKilledExtraUnthreadedCBs[ iCB ] ]](
			eInflictor,
			attacker,
			iDamage,
			sMeansOfDeath,
			sWeapon,
			vDir,
			sHitLoc,
			psOffsetTime,
			deathAnimDuration );
	}	
	
	self.wantSafeSpawn = false;
	perks = maps\mp\gametypes\_globallogic::getPerks( attacker );
	killstreaks = maps\mp\gametypes\_globallogic::getKillstreaks( attacker );
	
	// let the player watch themselves die
	wait ( 0.25 );

	//check if killed by a sniper
	weaponClass = maps\mp\gametypes\_missions::getWeaponClass( sWeapon );
	if ( weaponClass == "weapon_sniper" )
	{
		self thread maps\mp\gametypes\_battlechatter_mp::KilledBySniper( attacker );
	}
	else
	{
		self thread maps\mp\gametypes\_battlechatter_mp::PlayerKilled( attacker );
	}	
	self.cancelKillcam = false;
	self thread maps\mp\gametypes\_killcam::cancelKillCamOnUse();
	maps\mp\gametypes\_globallogic_utils::waitForTimeOrNotifies( 1.75 );
	self notify ( "death_delay_finished" );

/#
	if ( GetDvarInt( #"scr_forcekillcam" ) != 0 )
	{
		doKillcam = true;

		if ( lpattacknum < 0 )
			lpattacknum = self getEntityNumber();
	}
#/

	if ( game["state"] != "playing" )
	{
		// if no longer playing then this was probably the kill that ended the round
		// store off the killcam info
		level thread maps\mp\gametypes\_killcam::startFinalKillcam( lpattacknum, self getEntityNumber(), killcamentity, killcamentityindex, killcamentitystarttime, sWeapon, self.deathTime, deathTimeOffset, psOffsetTime, perks, killstreaks, attacker );
		return;
	}
	
	respawnTimerStartTime = gettime();
	
	if ( !self.cancelKillcam && doKillcam && level.killcam )
	{
		livesLeft = !(level.numLives && !self.pers["lives"]);
		timeUntilSpawn =  maps\mp\gametypes\_globallogic_spawn::TimeUntilSpawn( true );
		willRespawnImmediately = livesLeft && (timeUntilSpawn <= 0);
			
		self thread maps\mp\_tutorial::tutorial_display_tip();
		self maps\mp\gametypes\_killcam::killcam( lpattacknum, self getEntityNumber(), killcamentity, killcamentityindex, killcamentitystarttime, sWeapon, self.deathTime, deathTimeOffset, psOffsetTime, willRespawnImmediately, maps\mp\gametypes\_globallogic_utils::timeUntilRoundEnd(), perks, killstreaks, attacker );
	}
	
	if ( game["state"] != "playing" )
	{
		self.sessionstate = "dead";
		self.spectatorclient = -1;
		self.killcamtargetentity = -1;
		self.killcamentity = -1;
		self.archivetime = 0;
		self.psoffsettime = 0;
		return;
	}
	
	WaitTillKillStreakDone();

	// class may be undefined if we have changed teams
	if ( maps\mp\gametypes\_globallogic_utils::isValidClass( self.class ) )
	{
		timePassed = (gettime() - respawnTimerStartTime) / 1000;
		self thread [[level.spawnClient]]( timePassed );
	}
}

updateGlobalBotKilledCounter()
{
	self endon("disconnect");
	wait( .05 );
	maps\mp\gametypes\_globallogic_utils::WaitTillSlowProcessAllowed();
	
	if ( isDefined( self.pers["isBot"] ) )
	{
		level.globalLarrysKilled++;
	}
}


WaitTillKillStreakDone()
{
	if( isdefined( self.killstreak_waitamount ) )
	{
		starttime = gettime();
		waitTime = self.killstreak_waitamount * 1000;
		
		while( (gettime() < (starttime+waitTime)) && isdefined( self.killstreak_waitamount ) )
		{
			wait( 0.1 );
		}
		
		//Plus a small amount so we can see our dead body
		wait( 2.0 );
	
		self.killstreak_waitamount = undefined;
	}
}

TeamKillKick()
{
	self  maps\mp\gametypes\_globallogic_score::incPersStat( "sessionbans", 1 );			
	
	self endon("disconnect");
	waittillframeend;
	
	//for test purposes lets lock them out of certain game type for 2mins

	playlistbanquantum = maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillerplaylistbanquantum" );
	playlistbanpenalty = maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillerplaylistbanpenalty" );
	if ( playlistbanquantum > 0 && playlistbanpenalty > 0 )
	{	
		timeplayedtotal = self maps\mp\gametypes\_persistence::statGet( "time_played_total" );
		minutesplayed = timeplayedtotal / 60;
		
		freebees = 2;
		
		banallowance = int( floor(minutesplayed / playlistbanquantum) ) + freebees;
		
		if ( self.sessionbans > banallowance )
		{
			self maps\mp\gametypes\_persistence::statSet( "gametypeban", timeplayedtotal + (playlistbanpenalty * 60), false ); 
		}
	}
	
	// no waiting because then they could quit and rejoin before the ban
//	self setLowerMessage( &"MP_FRIENDLY_FIRE_WILL_NOT", 2 );

	if ( self is_bot() )
	{
		level notify( "bot_kicked", self.team );
	}
	
	ban( self getentitynumber(), 1 );
	maps\mp\gametypes\_globallogic_audio::leaderDialog( "kicked" );		
}

TeamKillDelay()
{
	teamkills = self.pers["teamkills_nostats"];
	if ( level.minimumAllowedTeamKills < 0 || teamkills <= level.minimumAllowedTeamKills )
		return 0;

	exceeded = (teamkills - level.minimumAllowedTeamKills);
	return maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillspawndelay" ) * exceeded;
}


ShouldTeamKillKick(teamKillDelay)
{
	if ( teamKillDelay && maps\mp\gametypes\_tweakables::getTweakableValue( "team", "kickteamkillers" ) )
	{
		// if its more then 5 seconds into the match and we have a delay then just kick them
		if ( maps\mp\gametypes\_globallogic_utils::getTimePassed() >= 5000 )
		{
			return true;
		}
		
		// if its under 5 seconds into the match only kick them if they have killed more then one players so far
		if ( self.pers["teamkills_nostats"] > 1  )
		{
			return true;
		}
	}
	
	return false;
}

reduceTeamKillsOverTime()
{
	timePerOneTeamkillReduction = 20.0;
	reductionPerSecond = 1.0 / timePerOneTeamkillReduction;
	
	while(1)
	{
		if ( isAlive( self ) )
		{
			self.pers["teamkills_nostats"] -= reductionPerSecond;
			if ( self.pers["teamkills_nostats"] < level.minimumAllowedTeamKills )
			{
				self.pers["teamkills_nostats"] = level.minimumAllowedTeamKills;
				break;
			}
		}
		wait 1;
	}
}


IgnoreTeamKills( sWeapon, sMeansOfDeath )
{
	if ( sMeansOfDeath == "MOD_MELEE" )
		return false;
		
	if ( sWeapon == "briefcase_bomb_mp" )
		return true;
		
	if ( sWeapon == "supplydrop_mp" )
		return true;
	
//	if ( isSubStr( sWeapon, "mine_bouncing_betty_" ) )
//		return true;
		
	return false;	
}


Callback_PlayerLastStand( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	maps\mp\_laststand::playerlaststand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration );	
}


damageShellshockAndRumble( eAttacker, eInflictor, sWeapon, sMeansOfDeath, iDamage )
{
	self thread maps\mp\gametypes\_weapons::onWeaponDamage( eAttacker, eInflictor, sWeapon, sMeansOfDeath, iDamage );
	self PlayRumbleOnEntity( "damage_heavy" );
}


createDeadBody( iDamage, sMeansOfDeath, sWeapon, sHitLoc, vDir, vAttackerOrigin, deathAnimDuration, eInflictor, ragdoll_jib, body )
{
	if ( sMeansOfDeath == "MOD_HIT_BY_OBJECT" && self GetStance() == "prone" )
	{
		self.body = body;
		if ( !isDefined( self.switching_teams ) )
			thread maps\mp\gametypes\_deathicons::addDeathicon( body, self, self.team, 5.0 );

		return;
	}

	if ( IsDefined( level.ragdoll_override ) && self [[level.ragdoll_override]]() )
	{
		return;
	}

	if ( ragdoll_jib || self isOnLadder() || self isMantling() || sMeansOfDeath == "MOD_CRUSH" || sMeansOfDeath == "MOD_HIT_BY_OBJECT" )
		body startRagDoll();

	if ( !self IsOnGround() )
	{
		if ( GetDvarInt( #"scr_disable_air_death_ragdoll" ) == 0 )
		{
			body startRagDoll();
		}
	}

	if ( self is_explosive_ragdoll( sWeapon, eInflictor ) )
	{
		body start_explosive_ragdoll( vDir, sWeapon );
	}

	thread delayStartRagdoll( body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath );

	if( sMeansOfDeath == "MOD_BURNED" || isdefined( self.burning ) )
	{
		body maps\mp\_burnplayer::burnedToDeath();		
	}	
	if ( sMeansOfDeath == "MOD_CRUSH" )
	{
		body maps\mp\gametypes\_globallogic_vehicle::vehicleCrush();
	}
	
	self.body = body;
	if ( !isDefined( self.switching_teams ) )
		thread maps\mp\gametypes\_deathicons::addDeathicon( body, self, self.team, 5.0 );
}

is_explosive_ragdoll( weapon, inflictor )
{
	if ( !IsDefined( weapon ) )
	{
		return false;
	}

	// destructible explosives
	if ( weapon == "destructible_car_mp" || weapon == "explodable_barrel_mp" )
	{
		return true;
	}

	// special explosive weapons
	if ( weapon == "sticky_grenade_mp" || weapon == "explosive_bolt_mp" )
	{
		if ( IsDefined( inflictor ) && IsDefined( inflictor.stuckToPlayer ) )
		{
			if ( inflictor.stuckToPlayer == self )
			{
				return true;
			}
		}
	}

	return false;
}

start_explosive_ragdoll( dir, weapon )
{
	if ( !IsDefined( self ) )
	{
		return;
	}

	x = RandomIntRange( 50, 100 );
	y = RandomIntRange( 50, 100 );
	z = RandomIntRange( 10, 20 );

	if ( IsDefined( weapon ) && ( weapon == "sticky_grenade_mp" || weapon == "explosive_bolt_mp" ) )
	{
		if ( IsDefined( dir ) && LengthSquared( dir ) > 0 )
		{
			x = dir[0] * x;
			y = dir[1] * y;
		}
	}
	else
	{
		if ( cointoss() )
		{
			x = x * -1;
		}
		if ( cointoss() )
		{
			y = y * -1;
		}
	}

	self StartRagdoll();
	self LaunchRagdoll( ( x, y, z ) );
}


notifyConnecting()
{
	waittillframeend;

	if( isDefined( self ) )
		level notify( "connecting", self );
}


delayStartRagdoll( ent, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath )
{
	if ( isDefined( ent ) )
	{
		deathAnim = ent getcorpseanim();
		if ( animhasnotetrack( deathAnim, "ignore_ragdoll" ) )
			return;
	}
	
	if ( level.oldschool )
	{
		if ( !isDefined( vDir ) )
			vDir = (0,0,0);
		
		explosionPos = ent.origin + ( 0, 0, maps\mp\gametypes\_globallogic_utils::getHitLocHeight( sHitLoc ) );
		explosionPos -= vDir * 20;
		//thread maps\mp\gametypes\_globallogic_utils::debugLine( ent.origin + (0,0,(explosionPos[2] - ent.origin[2])), explosionPos );
		explosionRadius = 40;
		explosionForce = .75;
		if ( sMeansOfDeath == "MOD_IMPACT" || sMeansOfDeath == "MOD_EXPLOSIVE" || isSubStr(sMeansOfDeath, "MOD_GRENADE") || isSubStr(sMeansOfDeath, "MOD_PROJECTILE") || sHitLoc == "head" || sHitLoc == "helmet" )
		{
			explosionForce = 2.5;
		}
		
		ent startragdoll( 1 );
		
		wait .05;
		
		if ( !isDefined( ent ) )
			return;
		
		// apply extra physics force to make the ragdoll go crazy
		physicsExplosionSphere( explosionPos, explosionRadius, explosionRadius/2, explosionForce );
		return;
	}
	
	wait( 0.2 );
	
	if ( !isDefined( ent ) )
		return;
	
	if ( ent isRagDoll() )
		return;
	
	deathAnim = ent getcorpseanim();

	startFrac = 0.35;

	if ( animhasnotetrack( deathAnim, "start_ragdoll" ) )
	{
		times = getnotetracktimes( deathAnim, "start_ragdoll" );
		if ( isDefined( times ) )
			startFrac = times[0];
	}

	waitTime = startFrac * getanimlength( deathAnim );
	wait( waitTime );

	if ( isDefined( ent ) )
	{
		println( "Ragdolling after " + waitTime + " seconds" );
		ent startragdoll( 1 );
	}
}

trackAttackerDamage( eAttacker, iDamage, sMeansOfDeath, sWeapon )
{
	Assert( isPlayer( eAttacker ) );
	
	if ( !isdefined( self.attackerData[eAttacker.clientid] ) )
	{
		self.attackerDamage[eAttacker.clientid] = spawnstruct();
		self.attackerDamage[eAttacker.clientid].damage = iDamage;
		self.attackerDamage[eAttacker.clientid].meansOfDeath = sMeansOfDeath;
		self.attackerDamage[eAttacker.clientid].weapon = sWeapon;
		self.attackerDamage[eAttacker.clientid].time = getTime();
		self.attackers[ self.attackers.size ] = eAttacker;
		// we keep an array of attackers by their client ID so we can easily tell
		// if they're already one of the existing attackers in the above if().
		// we store in this array data that is useful for other things, like challenges
		self.attackerData[eAttacker.clientid] = false;
	}
	else
	{
		self.attackerDamage[eAttacker.clientid].damage += iDamage;
		self.attackerDamage[eAttacker.clientid].meansOfDeath = sMeansOfDeath;
		self.attackerDamage[eAttacker.clientid].weapon = sWeapon;
		if ( !isdefined( self.attackerDamage[eAttacker.clientid].time ) )
			self.attackerDamage[eAttacker.clientid].time = getTime();
	}

	self.attackerDamage[eAttacker.clientid].lasttimedamaged = getTime();
	if ( maps\mp\gametypes\_weapons::isPrimaryWeapon( sWeapon ) )
		self.attackerData[eAttacker.clientid] = true;
}

giveInflictorOwnerAssist( eAttacker, eInflictor, iDamage, sMeansOfDeath, sWeapon )
{
	if ( !isDefined( eInflictor ) )
		return;
		
	if ( !isDefined( eInflictor.owner ) )
		return;
		
	if ( !IsDefined( eInflictor.ownerGetsAssist ) )
		return;
		
	if ( !eInflictor.ownerGetsAssist )
		return;
		
	Assert( isPlayer( eInflictor.owner ) );
	
	trackAttackerDamage( eInflictor.owner, iDamage, sMeansOfDeath, sWeapon );
}

updateMeansOfDeath( sWeapon, sMeansOfDeath )
{
	// we do not want the melee icon to show up for dog attacks
	// AE 10-22-09: added the check for the crossbow so that it'll show the right icon
	switch(sWeapon)
	{
	case "crossbow_mp":
	case "knife_ballistic_mp":
		{
			if ( ( sMeansOfDeath != "MOD_HEAD_SHOT" ) && ( sMeansOfDeath != "MOD_MELEE" ) )
			{
				sMeansOfDeath = "MOD_PISTOL_BULLET";
			}
		}
		break;
	case "dog_bite_mp":
		sMeansOfDeath = "MOD_PISTOL_BULLET";
		break;
	case "destructible_car_mp":
		sMeansOfDeath = "MOD_EXPLOSIVE";
		break;
	case "explodable_barrel_mp":
		sMeansOfDeath = "MOD_EXPLOSIVE";
		break;
	}

	return sMeansOfDeath;
}

updateAttacker( attacker )
{
	if( isai(attacker) && isDefined( attacker.script_owner ) )
	{
		// if the person who called the dogs in switched teams make sure they don't
		// get penalized for the kill
		if ( !level.teambased || attacker.script_owner.team != self.team )
			attacker = attacker.script_owner;
	}
	
	if( attacker.classname == "script_vehicle" && isDefined( attacker.owner ) )
	{
		attacker notify("killed",self);

		attacker = attacker.owner;
	}

	if( isai(attacker) )
		attacker notify("killed",self);
		
	if ( ( isdefined ( self.capturingLastFlag ) ) && ( self.capturingLastFlag == true ) )
	{
		attacker.lastCapKiller = true;
	}
	
	return attacker;
}

updateInflictor( eInflictor )
{
	if( IsDefined( eInflictor ) && eInflictor.classname == "script_vehicle" )
	{
		eInflictor notify("killed",self);
	}
	
	return eInflictor;
}

updateWeapon( eInflictor, sWeapon )
{
	// explosive barrel/car detection
	if ( sWeapon == "none" && isDefined( eInflictor ) )
	{
		if ( isDefined( eInflictor.targetname ) && eInflictor.targetname == "explodable_barrel" )
			sWeapon = "explodable_barrel_mp";
		else if ( isDefined( eInflictor.destructible_type ) && isSubStr( eInflictor.destructible_type, "vehicle_" ) )
			sWeapon = "destructible_car_mp";
	}
	
	return sWeapon;
}

getClosestKillcamEntity( attacker, killCamEntities )
{
		closestKillcamEnt = undefined;
		closestKillcamEntDist = undefined;
		origin = undefined;
		
		for ( killcamEntIndex = 0; killcamEntIndex < killCamEntities.size; killcamEntIndex++ )
		{
			killcamEnt = killCamEntities[killcamEntIndex];
			if ( killcamEnt == attacker )
				continue;
			
			origin = killcamEnt.origin;
			if ( IsDefined( killcamEnt.offsetPoint ) )
				origin += killcamEnt.offsetPoint;
	
			dist = DistanceSquared( self.origin, origin );
	
			if ( !IsDefined( closestKillcamEnt ) || dist < closestKillcamEntDist )
			{
				closestKillcamEnt = killcamEnt;
				closestKillcamEntDist = dist;
			}
		}
		
		return closestKillcamEnt;
}

getKillcamEntity( attacker, eInflictor, sWeapon )
{
	if ( !isDefined( eInflictor ) )
		return undefined;

	if ( eInflictor == attacker )
	{
		if( !IsDefined( eInflictor.isMagicBullet ) )
			return undefined;
		if( IsDefined( eInflictor.isMagicBullet ) && !eInflictor.isMagicBullet )
			return undefined;
	}
	else if ( isdefined( level.levelSpecificKillcam ) )
	{
		levelSpecificKillcamEnt = self [[level.levelSpecificKillcam]]();
		if ( isdefined( levelSpecificKillcamEnt ) )
			return levelSpecificKillcamEnt;
	}
	
	if ( sWeapon == "m220_tow_mp" )
		return undefined;
	
	if ( isDefined(eInflictor.killCamEnt) )
	{
		// this is the case with the player helis
		if ( eInflictor.killCamEnt == attacker )
			return undefined;
			
		return eInflictor.killCamEnt;
	}
	else if ( isDefined(eInflictor.killCamEntities) )
	{
		return getClosestKillcamEntity( attacker, eInflictor.killCamEntities );
	}
	
	if ( isDefined( eInflictor.script_gameobjectname ) && eInflictor.script_gameobjectname == "bombzone" )
		return eInflictor.killCamEnt;
	
	//if ( eInflictor.classname == "script_origin" || eInflictor.classname == "script_model" || eInflictor.classname == "script_brushmodel" )
	//	return undefined; // probably a barrel or a car... code does airstrike cam for these things which looks bad

	return eInflictor;
}
	
playKillBattleChatter( attacker, sWeapon )
{
	if( IsPlayer( attacker ) )
	{
		if( isDefined(level.bcKillInformProbability) && randomIntRange( 0, 100 ) >= level.bcKillInformProbability )
		{
			if ( !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon ) )
			{
				level thread maps\mp\gametypes\_battlechatter_mp::sayLocalSoundDelayed( attacker, "kill", "infantry", 0.75 );
			}
		}
	}
}
 